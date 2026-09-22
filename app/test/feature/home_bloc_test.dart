import 'dart:async';

import 'package:app/data/repository/user_data/user_data_repository.dart';
import 'package:app/feature/home/bloc/home_bloc.dart';
import 'package:app/feature/home/home_screen.dart';
import 'package:data/data.dart' hide Page;
import 'package:data/data.dart' as data show Page;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';
import 'package:provider/provider.dart';

class MockUserDataRepository implements UserDataRepository {
  final StreamController<UserData> _controller =
      StreamController<UserData>.broadcast();
  UserData _currentData = const UserData();

  @override
  Stream<UserData> get data => _controller.stream;

  void emitData(UserData userData) {
    _currentData = userData;
    _controller.add(userData);
  }

  @override
  Future<Result<void>> setSourceId(String sourceId) async {
    _currentData = _currentData.copyWith(sourceId: sourceId);
    _controller.add(_currentData);
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> setDynamicColorPreference(bool useDynamicColor) async {
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> setThemeConfig(ThemeConfig themeConfig) async {
    return const Result.ok(null);
  }

  void dispose() {
    _controller.close();
  }
}

/// 可控的视频 Feed 数据源，避免测试发起真实网络请求
class FakeVideoFeed implements VideoFeedRemoteDataSource {
  FakeVideoFeed({
    required this.id,
    required this.title,
    required this.pages,
    this.failure = false,
  });

  @override
  final String id;
  @override
  final String title;
  final int pages;
  final bool failure;

  int fetchCount = 0;

  @override
  String get sourceId => 'fake';

  @override
  Future<Result<data.Page<VideoModel>>> fetchFeed({int? pageKey}) async {
    fetchCount++;
    if (failure) return Result.error(Exception('boom'));
    final page = pageKey ?? 1;
    return Result.ok(
      data.Page<VideoModel>(
        number: page,
        totalPages: pages,
        data: [
          VideoModel(
            id: '$id-$page',
            title: '$title 第 $page 页',
            url: 'https://example.com/$id/$page',
          ),
        ],
      ),
    );
  }
}

/// 可控的直播 Feed 数据源
class FakeLiveFeed implements LiveRoomFeedRemoteDataSource {
  FakeLiveFeed({required this.id, required this.title});

  @override
  final String id;
  @override
  final String title;

  @override
  String get sourceId => 'fake';

  @override
  Future<Result<data.Page<LiveRoomModel>>> fetchFeed({int? pageKey}) async {
    return Result.ok(
      data.Page<LiveRoomModel>(
        number: pageKey ?? 1,
        totalPages: 1,
        data: const [
          LiveRoomModel(
            id: 230023,
            title: '测试直播间',
            url: 'https://example.com/live/230023',
            isLive: true,
            creatorProfileName: '主播',
          ),
        ],
      ),
    );
  }
}

class FakeLiveRoomSearch implements LiveRoomSearchRemoteDataSource {
  const FakeLiveRoomSearch();

  @override
  String get sourceId => 'fake';

  @override
  List<FilterGroup> get filters => const [];

  @override
  List<SortOption> get sortOptions => const [];

  @override
  Future<Result<data.Page<LiveRoomModel>>> searchLiveRoom(
    String query, {
    int? pageKey,
  }) async => Result.ok(
    data.Page<LiveRoomModel>(number: 1, totalPages: 1, data: const []),
  );
}

class FakeMediaSource implements MediaSource {
  FakeMediaSource({
    required this.id,
    required this.name,
    this.videoFeedDataSources = const [],
    this.liveRoomFeedDataSources = const [],
    this.liveRoomSearchDataSource,
  });

  @override
  final String id;
  @override
  final String name;
  @override
  final List<VideoFeedRemoteDataSource> videoFeedDataSources;
  @override
  final List<LiveRoomFeedRemoteDataSource> liveRoomFeedDataSources;
  @override
  final LiveRoomSearchRemoteDataSource? liveRoomSearchDataSource;

  @override
  AggregateSearchRemoteDataSource? get aggregateSearchDataSource => null;
  @override
  CreatorProfileSearchRemoteDataSource? get creatorProfileSearchDataSource =>
      null;
  @override
  VideoSearchRemoteDataSource? get videoSearchDataSource => null;
  @override
  SearchSuggestRemoteDataSource? get searchSuggestDataSource => null;
  @override
  VideoDetailRemoteDataSource? get videoDetailDataSource => null;
  @override
  VideoCommentRemoteDataSource? get videoCommentDataSource => null;

  @override
  Future<void> close() async {}
}

void main() {
  late MockUserDataRepository mockUserDataRepository;
  late FakeVideoFeed biliVideoFeed;
  late List<MediaSource> mediaSources;

  HomeBloc buildBloc() => HomeBloc(
    userDataRepository: mockUserDataRepository,
    mediaSources: mediaSources,
  );

  Widget buildScreen(HomeBloc bloc) => Provider<List<MediaSource>>.value(
    value: mediaSources,
    child: MaterialApp(
      home: BlocProvider<HomeBloc>.value(
        value: bloc,
        child: HomeScreen(
          onLive: (_) {},
          navigateToSearchResult: (_) {},
          onSpace: (_) {},
          onVideo: (_) {},
        ),
      ),
    ),
  );

  setUp(() {
    mockUserDataRepository = MockUserDataRepository();
    biliVideoFeed = FakeVideoFeed(id: 'recommend', title: '推荐视频', pages: 2);
    mediaSources = [
      FakeMediaSource(
        id: 'bilibili',
        name: 'Bilibili',
        videoFeedDataSources: [biliVideoFeed],
        liveRoomFeedDataSources: [
          FakeLiveFeed(id: 'recommend_live', title: '推荐直播'),
        ],
        liveRoomSearchDataSource: const FakeLiveRoomSearch(),
      ),
      FakeMediaSource(
        id: 'youtube',
        name: 'YouTube',
        videoFeedDataSources: [
          FakeVideoFeed(id: 'trending', title: '时下热门', pages: 1),
        ],
      ),
    ];
  });

  tearDown(() {
    mockUserDataRepository.dispose();
  });

  group('HomeBloc Tests', () {
    test('Loads feeds of the active source on start', () async {
      final bloc = buildBloc();
      addTearDown(bloc.close);

      await expectLater(
        bloc.stream.firstWhere(
          (state) =>
              state.videoSections.isNotEmpty &&
              state.videoSections.first.status == FeedStatus.success,
        ),
        completes,
      );
      expect(bloc.state.videoSections.first.items, hasLength(1));
      expect(bloc.state.liveSections.first.items, hasLength(1));
      expect(bloc.state.videoSections.first.hasMore, isTrue);
    });

    test('Appends the next page for a video feed', () async {
      final bloc = buildBloc();
      addTearDown(bloc.close);

      await bloc.stream.firstWhere(
        (state) =>
            state.videoSections.isNotEmpty &&
            state.videoSections.first.status == FeedStatus.success,
      );

      bloc.add(FeedNextPageRequested('recommend'));
      await bloc.stream.firstWhere(
        (state) => state.videoSections.first.items.length == 2,
      );

      expect(bloc.state.videoSections.first.pageKey, 2);
      expect(bloc.state.videoSections.first.hasMore, isFalse);
    });

    test('Marks a section as failed when the feed request fails', () async {
      mediaSources = [
        FakeMediaSource(
          id: 'bilibili',
          name: 'Bilibili',
          videoFeedDataSources: [
            FakeVideoFeed(
              id: 'recommend',
              title: '推荐视频',
              pages: 1,
              failure: true,
            ),
          ],
        ),
      ];
      final bloc = buildBloc();
      addTearDown(bloc.close);

      await bloc.stream.firstWhere(
        (state) =>
            state.videoSections.isNotEmpty &&
            state.videoSections.first.status == FeedStatus.failure,
      );

      expect(bloc.state.videoSections.first.isFailure, isTrue);
    });

    test('Emits updated sourceId when UserData changes', () async {
      final bloc = buildBloc();
      addTearDown(bloc.close);
      await pumpEventQueue();

      mockUserDataRepository.emitData(const UserData(sourceId: 'youtube'));

      await expectLater(
        bloc.stream.firstWhere((state) => state.sourceId == 'youtube'),
        completes,
      );
    });

    test(
      'ServiceSourceChanged event triggers repository setSourceId',
      () async {
        final bloc = buildBloc();
        addTearDown(bloc.close);

        bloc.add(ServiceSourceChanged('youtube'));

        await expectLater(
          bloc.stream.firstWhere((state) => state.sourceId == 'youtube'),
          completes,
        );
      },
    );

    test('FilterSelected narrows the visible sections', () async {
      final bloc = buildBloc();
      addTearDown(bloc.close);

      await bloc.stream.firstWhere(
        (state) =>
            state.videoSections.isNotEmpty &&
            state.videoSections.first.status == FeedStatus.success,
      );

      bloc.add(FilterSelected('recommend_live'));
      await bloc.stream.firstWhere(
        (state) => state.filterId == 'recommend_live',
      );

      expect(bloc.state.visibleVideoSections, isEmpty);
      expect(bloc.state.visibleLiveSections, hasLength(1));
    });
  });

  group('HomeScreen Widget Tests', () {
    testWidgets('Renders the active source and its feed sections', (
      tester,
    ) async {
      final bloc = buildBloc();
      addTearDown(bloc.close);

      await tester.pumpWidget(buildScreen(bloc));
      await tester.pumpAndSettle();

      expect(find.text('Bilibili'), findsWidgets);
      expect(find.text('全部推荐'), findsOneWidget);
      expect(find.text('推荐直播'), findsWidgets);
      expect(find.text('推荐视频'), findsWidgets);
    });

    testWidgets('Hides the live entry for sources without live support', (
      tester,
    ) async {
      final bloc = buildBloc();
      addTearDown(bloc.close);

      await tester.pumpWidget(buildScreen(bloc));
      await tester.pumpAndSettle();
      mockUserDataRepository.emitData(const UserData(sourceId: 'youtube'));
      await tester.pumpAndSettle();

      expect(find.text('YouTube'), findsWidgets);
      expect(find.byTooltip('直达直播间'), findsNothing);
      expect(find.byTooltip('访问创作者频道'), findsOneWidget);
    });

    testWidgets('Shows a placeholder notice for local-only filters', (
      tester,
    ) async {
      final bloc = buildBloc();
      addTearDown(bloc.close);

      await tester.pumpWidget(buildScreen(bloc));
      await tester.pumpAndSettle();

      await tester.tap(find.text('我的收藏'));
      await tester.pumpAndSettle();

      expect(find.text('我的收藏 暂未开放'), findsOneWidget);
    });

    testWidgets('Pull to refresh re-fetches the feeds', (tester) async {
      final bloc = buildBloc();
      addTearDown(bloc.close);

      await tester.pumpWidget(buildScreen(bloc));
      await tester.pumpAndSettle();

      final fetchCountBeforeRefresh = biliVideoFeed.fetchCount;
      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      expect(biliVideoFeed.fetchCount, greaterThan(fetchCountBeforeRefresh));
    });

    testWidgets('Enforces text input length limits on search input field', (
      tester,
    ) async {
      final bloc = buildBloc();
      addTearDown(bloc.close);

      await tester.pumpWidget(buildScreen(bloc));
      await tester.pumpAndSettle();

      final searchTextField = tester.widget<TextField>(
        find.byType(TextField).first,
      );
      expect(searchTextField.maxLength, 200);
      expect(
        searchTextField.maxLengthEnforcement,
        MaxLengthEnforcement.enforced,
      );
    });
  });
}
