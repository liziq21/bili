import 'package:app/data/repository/search_contents_repository.dart';
import 'package:app/feature/search/bloc/search_result_bloc.dart';
import 'package:app/feature/search/search_result_screen.dart';
import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' hide Page;
import 'package:model/model.dart';

// ignore_for_file: use_primary_constructors

class FakeVideoSearchRepository
    implements SearchContentsRepository<VideoModel> {
  @override
  List<FilterGroup> get filters => const [];

  @override
  List<SortOption> get sortOptions => const [];

  @override
  Future<PagedResult<VideoModel>> search(SearchQuery searchQuery) async {
    return Result.ok(Page<VideoModel>(data: [], number: 1, totalPages: 1));
  }
}

class FakeCreatorProfileSearchRepository
    implements SearchContentsRepository<CreatorProfile> {
  @override
  List<FilterGroup> get filters => const [];

  @override
  List<SortOption> get sortOptions => const [];

  @override
  Future<PagedResult<CreatorProfile>> search(SearchQuery searchQuery) async {
    return Result.ok(Page<CreatorProfile>(data: [], number: 1, totalPages: 1));
  }
}

void main() {
  testWidgets(
    'SearchResultScreen renders fallback tab headers without raw identifier key',
    (tester) async {
      final videoRepo = FakeVideoSearchRepository();
      final creatorRepo = FakeCreatorProfileSearchRepository();

      final videoBloc = SearchResultBloc<VideoModel>(
        searchContentsRepository: videoRepo,
      );
      final creatorBloc = SearchResultBloc<CreatorProfile>(
        searchContentsRepository: creatorRepo,
      );

      addTearDown(videoBloc.close);
      addTearDown(creatorBloc.close);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<SearchResultBloc<VideoModel>>.value(
                value: videoBloc,
              ),
              BlocProvider<SearchResultBloc<CreatorProfile>>.value(
                value: creatorBloc,
              ),
            ],
            child: SearchResultScreen(query: 'Flutter', onBackClick: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Chinese fallback labels should be rendered when AppLocalizations is null
      expect(find.text('创作者'), findsOneWidget);
      expect(find.text('视频'), findsOneWidget);
      expect(find.text('creatorProfile'), findsNothing);
    },
  );

  testWidgets(
    'SearchResultScreen allows switching tabs between creator profiles and videos',
    (tester) async {
      final videoRepo = FakeVideoSearchRepository();
      final creatorRepo = FakeCreatorProfileSearchRepository();

      final videoBloc = SearchResultBloc<VideoModel>(
        searchContentsRepository: videoRepo,
      );
      final creatorBloc = SearchResultBloc<CreatorProfile>(
        searchContentsRepository: creatorRepo,
      );

      addTearDown(videoBloc.close);
      addTearDown(creatorBloc.close);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<SearchResultBloc<VideoModel>>.value(
                value: videoBloc,
              ),
              BlocProvider<SearchResultBloc<CreatorProfile>>.value(
                value: creatorBloc,
              ),
            ],
            child: SearchResultScreen(query: 'Flutter', onBackClick: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('视频'));
      await tester.pumpAndSettle();

      expect(find.text('视频'), findsOneWidget);
    },
  );
}
