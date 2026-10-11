import 'package:app/data/repository/app_search_suggest_repository.dart';
import 'package:app/data/repository/search/app_creator_profile_search_repository.dart';
import 'package:app/data/repository/search/app_live_room_search_repository.dart';
import 'package:app/data/repository/search/app_video_search_repository.dart';
import 'package:app/data/repository/search_contents_repository.dart';
import 'package:app/data/repository/search_suggest_repository.dart';
import 'package:app/data/repository/video_comment_repository.dart';
import 'package:app/data/repository/video_detail_repository.dart';
import 'package:app/providers/media_sources_provider.dart';
import 'package:app/providers/service_source_providers.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class _TrackingSource() extends MediaSource {
  @override
  String get id => 'tracking';

  @override
  String get name => 'Tracking';

  bool closed = false;

  @override
  Future<void> close() async {
    closed = true;
  }
}

void main() {
  Widget buildWithCatalog(Widget child) => Provider<MediaSourceCatalog>.value(
    value: defaultMediaSourceCatalog,
    child: MaterialApp(home: child),
  );

  testWidgets('injects repositories from the selected source capabilities', (
    tester,
  ) async {
    final found = <Type, Object?>{};
    await tester.pumpWidget(
      buildWithCatalog(
        ServiceSourceProviders(
          source: 'bilibili',
          child: Builder(
            builder: (context) {
              found[MediaSource] = context.read<MediaSource>();
              found[VideoSearchRepository] = context
                  .read<VideoSearchRepository>();
              found[CreatorProfileSearchRepository] = context
                  .read<CreatorProfileSearchRepository>();
              found[SearchSuggestRepository] = context
                  .read<SearchSuggestRepository>();
              found[LiveRoomSearchRepository] = context
                  .read<LiveRoomSearchRepository>();
              found[VideoDetailRepository] = context
                  .read<VideoDetailRepository>();
              found[VideoCommentRepository] = context
                  .read<VideoCommentRepository>();
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(found[MediaSource], isA<MediaSource>());
    expect(found[VideoSearchRepository], isA<AppVideoSearchRepository>());
    expect(
      found[CreatorProfileSearchRepository],
      isA<AppCreatorProfileSearchRepository>(),
    );
    expect(found[SearchSuggestRepository], isA<AppSearchSuggestRepository>());
    expect(found[LiveRoomSearchRepository], isA<AppLiveRoomSearchRepository>());
    expect(found[VideoDetailRepository], isA<AppVideoDetailRepository>());
    expect(found[VideoCommentRepository], isA<AppVideoCommentRepository>());
  });

  testWidgets(
    'injects YouTube search capabilities but omits unsupported ones',
    (tester) async {
      final found = <Type, Object?>{};
      await tester.pumpWidget(
        buildWithCatalog(
          ServiceSourceProviders(
            source: 'youtube',
            child: Builder(
              builder: (context) {
                found[VideoSearchRepository] = context
                    .read<VideoSearchRepository>();
                found[CreatorProfileSearchRepository] = context
                    .read<CreatorProfileSearchRepository>();
                found[SearchSuggestRepository] = context
                    .read<SearchSuggestRepository>();
                try {
                  found[VideoDetailRepository] = context
                      .read<VideoDetailRepository>();
                } on ProviderNotFoundException catch (error) {
                  found[VideoDetailRepository] = error;
                }
                try {
                  found[VideoCommentRepository] = context
                      .read<VideoCommentRepository>();
                } on ProviderNotFoundException catch (error) {
                  found[VideoCommentRepository] = error;
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(found[VideoSearchRepository], isA<AppVideoSearchRepository>());
      expect(
        found[CreatorProfileSearchRepository],
        isA<AppCreatorProfileSearchRepository>(),
      );
      expect(found[SearchSuggestRepository], isA<AppSearchSuggestRepository>());
      expect(found[VideoDetailRepository], isA<ProviderNotFoundException>());
      expect(found[VideoCommentRepository], isA<ProviderNotFoundException>());
    },
  );

  testWidgets('unknown sources fail before a route child is built', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildWithCatalog(
        ServiceSourceProviders(
          source: 'unknown',
          child: const Text('should not render'),
        ),
      ),
    );

    expect(tester.takeException(), isArgumentError);
    expect(find.text('should not render'), findsNothing);
  });

  testWidgets('empty catalogs do not create source instances', (tester) async {
    final catalog = MediaSourceCatalog(const []);
    await tester.pumpWidget(
      Provider<MediaSourceCatalog>.value(
        value: catalog,
        child: const MaterialApp(home: Text('empty catalog')),
      ),
    );

    expect(find.text('empty catalog'), findsOneWidget);
    expect(catalog.resolvePersisted(null), isNull);
  });

  testWidgets('route scope closes the source it created', (tester) async {
    late _TrackingSource created;
    final catalog = MediaSourceCatalog([
      MediaSourceDefinition(
        id: 'tracking',
        name: 'Tracking',
        create: () => created = _TrackingSource(),
      ),
    ]);

    await tester.pumpWidget(
      Provider<MediaSourceCatalog>.value(
        value: catalog,
        child: const MaterialApp(
          home: ServiceSourceProviders(
            source: 'tracking',
            child: Text('mounted'),
          ),
        ),
      ),
    );
    expect(created.closed, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    expect(created.closed, isTrue);
  });
}
