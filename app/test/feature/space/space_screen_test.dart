import 'package:app/data/repository/channel_videos_repository.dart';
import 'package:app/data/repository/creator_profile_repository.dart';
import 'package:app/data/repository/local_library_repository.dart';
import 'package:app/database/app_database.dart';
import 'package:app/datastore/preferences_data_source.dart';
import 'package:app/feature/space/space_screen.dart';
import 'package:app/l10n/localization_file/app_localizations_zh.dart';
import 'package:app/ui/video_card.dart';
import 'package:data/data.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' hide Page;
import 'package:model/model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:app/design/design.dart';

class const _TestMediaSource() extends MediaSource {
  @override
  String get id => 'test';

  @override
  String get name => 'Test';
}

class _FakeCreatorProfileRepository(
  var Result<CreatorProfile, Exception> result,
) implements CreatorProfileRepository {
  String? requestedId;

  @override
  Future<Result<CreatorProfile, Exception>> getProfile(String id) async {
    requestedId = id;
    return result;
  }
}

class _FakeChannelVideosRepository(
  final Map<int, Result<Page<VideoModel>, Exception>> responses,
) implements ChannelVideosRepository {
  final List<String> requestedChannels = [];
  final List<int> requestedPages = [];

  @override
  Future<Result<Page<VideoModel>, Exception>> fetchVideos({
    required String channelId,
    int page = 1,
    int pageSize = 30,
  }) async {
    requestedChannels.add(channelId);
    requestedPages.add(page);
    return responses[page] ??
        Result.success(
          Page<VideoModel>(number: page, totalPages: page, data: const []),
        );
  }
}

VideoModel _video(String id) =>
    VideoModel(id: id, title: 'Video $id', url: 'https://example.com/$id');

void main() {
  testWidgets('renders the creator profile header from repository data', (
    tester,
  ) async {
    const profile = CreatorProfile(
      id: 'creator-1',
      name: 'CodeCraft',
      description: 'Builds useful videos',
      subscribers: 12000,
      videos: 42,
    );
    final repository = _FakeCreatorProfileRepository(Result.success(profile));
    final l10n = AppLocalizationsZh();

    await tester.pumpWidget(
      RepositoryProvider<CreatorProfileRepository>.value(
        value: repository,
        child: const MaterialApp(home: SpaceScreen(mid: 'creator-1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.requestedId, 'creator-1');
    expect(find.byType(CircleAvatar), findsOneWidget);
    expect(find.byTooltip('CodeCraft'), findsOneWidget);
    expect(find.text('CodeCraft'), findsOneWidget);
    expect(find.text('Builds useful videos'), findsOneWidget);
    expect(find.text(l10n.creatorLabel('@creator-1')), findsOneWidget);
    expect(
      find.text(l10n.subscribersCount(l10n.countCompactWan('1.2'))),
      findsOneWidget,
    );
    expect(find.text(l10n.videosCount('42')), findsOneWidget);

    final expectedLabel = [
      'CodeCraft',
      l10n.creatorLabel('@creator-1'),
      'Builds useful videos',
      l10n.subscribersCount(l10n.countCompactWan('1.2')),
      l10n.videosCount('42'),
    ].join(l10n.commaSeparator);

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.container == true &&
            widget.excludeSemantics == true &&
            widget.properties.label == expectedLabel,
      ),
      findsOneWidget,
    );
  });

  testWidgets('triggers back callback when back button pressed', (
    tester,
  ) async {
    const profile = CreatorProfile(id: 'creator-1', name: 'CodeCraft');
    final repository = _FakeCreatorProfileRepository(Result.success(profile));
    var backPressed = false;

    await tester.pumpWidget(
      RepositoryProvider<CreatorProfileRepository>.value(
        value: repository,
        child: MaterialApp(
          home: SpaceScreen(
            mid: 'creator-1',
            onBackClick: () => backPressed = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final backButton = find.byIcon(AppIcons.back);
    expect(backButton, findsOneWidget);

    await tester.tap(backButton);
    await tester.pumpAndSettle();

    expect(backPressed, isTrue);
  });

  testWidgets('renders error view and triggers retry when pressed', (
    tester,
  ) async {
    final repository = _FakeCreatorProfileRepository(
      Result.error(Exception('Failed to load')),
    );
    final l10n = AppLocalizationsZh();

    await tester.pumpWidget(
      RepositoryProvider<CreatorProfileRepository>.value(
        value: repository,
        child: const MaterialApp(home: SpaceScreen(mid: 'creator-1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.loadFailedRetryLater), findsOneWidget);
    final retryButton = find.text(l10n.retry);
    expect(retryButton, findsOneWidget);

    repository.result = Result.success(
      const CreatorProfile(id: 'creator-1', name: 'CodeCraft'),
    );

    await tester.tap(retryButton);
    await tester.pumpAndSettle();

    expect(find.text('CodeCraft'), findsOneWidget);
  });

  testWidgets('renders the video tab and opens a video on tap', (tester) async {
    const profile = CreatorProfile(id: 'creator-1', name: 'CodeCraft');
    final profileRepository = _FakeCreatorProfileRepository(
      Result.success(profile),
    );
    final videosRepository = _FakeChannelVideosRepository({
      1: Result.success(
        Page(number: 1, totalPages: 1, data: [_video('v1'), _video('v2')]),
      ),
    });
    final opened = <String>[];
    final l10n = AppLocalizationsZh();

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<CreatorProfileRepository>.value(
            value: profileRepository,
          ),
          RepositoryProvider<ChannelVideosRepository>.value(
            value: videosRepository,
          ),
        ],
        child: MaterialApp(
          home: SpaceScreen(mid: 'creator-1', onVideo: opened.add),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.videoTab), findsOneWidget);
    expect(find.byType(VideoCard), findsNWidgets(2));
    expect(videosRepository.requestedChannels, ['creator-1']);
    expect(videosRepository.requestedPages, [1]);

    await tester.tap(find.byType(VideoCard).first);
    await tester.pump();

    expect(opened, ['v1']);
  });

  testWidgets('loads the next page when the grid reaches the end', (
    tester,
  ) async {
    const profile = CreatorProfile(id: 'creator-1', name: 'CodeCraft');
    final profileRepository = _FakeCreatorProfileRepository(
      Result.success(profile),
    );
    final videosRepository = _FakeChannelVideosRepository({
      1: Result.success(Page(number: 1, totalPages: 2, data: [_video('v1')])),
      2: Result.success(Page(number: 2, totalPages: 2, data: [_video('v2')])),
    });

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<CreatorProfileRepository>.value(
            value: profileRepository,
          ),
          RepositoryProvider<ChannelVideosRepository>.value(
            value: videosRepository,
          ),
        ],
        child: const MaterialApp(home: SpaceScreen(mid: 'creator-1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(videosRepository.requestedPages, [1, 2]);
    expect(find.text('Video v1'), findsOneWidget);
    expect(find.text('Video v2'), findsOneWidget);
  });

  testWidgets('shows an unsupported message without a videos capability', (
    tester,
  ) async {
    const profile = CreatorProfile(id: 'creator-1', name: 'CodeCraft');
    final profileRepository = _FakeCreatorProfileRepository(
      Result.success(profile),
    );
    final l10n = AppLocalizationsZh();

    await tester.pumpWidget(
      RepositoryProvider<CreatorProfileRepository>.value(
        value: profileRepository,
        child: const MaterialApp(home: SpaceScreen(mid: 'creator-1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.videoTab), findsOneWidget);
    expect(find.text(l10n.channelVideosUnsupported), findsOneWidget);
    expect(find.byType(VideoCard), findsNothing);
  });

  testWidgets('hides the videos tab without fetching when disabled', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final preferences = PreferencesDataSource(
      sharedPreferences: SharedPreferencesAsync(),
    );
    addTearDown(preferences.dispose);
    await preferences.set(
      PreferencesKey.channelTabVisibility,
      '{"videos":false}',
    );

    const profile = CreatorProfile(id: 'creator-1', name: 'CodeCraft');
    final profileRepository = _FakeCreatorProfileRepository(
      Result.success(profile),
    );
    final videosRepository = _FakeChannelVideosRepository({
      1: Result.success(Page(number: 1, totalPages: 1, data: [_video('v1')])),
    });
    final l10n = AppLocalizationsZh();

    await tester.pumpWidget(
      Provider<PreferencesDataSource>.value(
        value: preferences,
        child: MultiRepositoryProvider(
          providers: [
            RepositoryProvider<CreatorProfileRepository>.value(
              value: profileRepository,
            ),
            RepositoryProvider<ChannelVideosRepository>.value(
              value: videosRepository,
            ),
          ],
          child: const MaterialApp(home: SpaceScreen(mid: 'creator-1')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CodeCraft'), findsOneWidget);
    expect(find.text(l10n.videoTab), findsNothing);
    expect(find.byType(TabBar), findsNothing);
    expect(find.byType(VideoCard), findsNothing);
    expect(videosRepository.requestedPages, isEmpty);
  });

  testWidgets('subscribes and unsubscribes the creator locally', (
    tester,
  ) async {
    const profile = CreatorProfile(id: 'creator-1', name: 'CodeCraft');
    final profileRepository = _FakeCreatorProfileRepository(
      Result.success(profile),
    );
    final database = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    addTearDown(database.close);
    final library = LocalLibraryRepository(dao: database.localLibraryDao);

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<CreatorProfileRepository>.value(
            value: profileRepository,
          ),
          RepositoryProvider<LocalLibraryRepository>.value(value: library),
          RepositoryProvider<MediaSource>.value(
            value: const _TestMediaSource(),
          ),
        ],
        child: const MaterialApp(home: SpaceScreen(mid: 'creator-1')),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();

    expect(find.text('Subscribe'), findsOneWidget);

    await tester.tap(find.text('Subscribe'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();

    expect(
      await tester.runAsync(() => library.isSubscribed('test', 'creator-1')),
      isTrue,
    );
    expect(find.text('Unsubscribe'), findsOneWidget);

    await tester.tap(find.text('Unsubscribe'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();

    expect(
      await tester.runAsync(() => library.isSubscribed('test', 'creator-1')),
      isFalse,
    );
    expect(find.text('Subscribe'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
