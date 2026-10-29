import 'package:alchemist/alchemist.dart';
import 'package:app/data/repository/user_data/user_data_repository.dart';
import 'package:app/feature/home/bloc/home_bloc.dart';
import 'package:app/feature/home/home_screen.dart';
import 'package:app/providers/media_sources_provider.dart';
import 'package:data/data.dart' hide Page;
import 'package:data/data.dart' as data show Page;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:provider/provider.dart';

import 'golden_font.dart';

class _FakeUserDataRepository() implements UserDataRepository {
  @override
  Stream<UserData> get data => Stream.empty();

  @override
  Future<Result<void, Exception>> setSourceId(String sourceId) async =>
      Result.success(null);

  @override
  Future<Result<void, Exception>> setThemeConfig(
    ThemeConfig themeConfig,
  ) async => Result.success(null);

  @override
  Future<Result<void, Exception>> setDynamicColorPreference(
    bool useDynamicColor,
  ) async => Result.success(null);
}

class _FakeVideoFeed({required final int count})
    implements VideoFeedRemoteDataSource {
  @override
  String get sourceId => 'bilibili';

  @override
  String get id => 'popular';

  @override
  String get title => '热门';

  @override
  Future<Result<data.Page<VideoModel>, Exception>> fetchFeed({
    int? pageKey,
  }) async {
    return Result.success(
      data.Page(number: 1, totalPages: 1, data: _videos(count)),
    );
  }
}

class _FakeSource({required final int count}) implements MediaSource {
  @override
  String get id => 'bilibili';

  @override
  String get name => '哔哩哔哩';

  @override
  List<VideoFeedRemoteDataSource> get videoFeedDataSources => [
    _FakeVideoFeed(count: count),
  ];

  @override
  List<LiveRoomFeedRemoteDataSource> get liveRoomFeedDataSources => const [];

  @override
  LiveRoomSearchRemoteDataSource? get liveRoomSearchDataSource => null;

  @override
  MediaStreamRemoteDataSource? get mediaStreamDataSource => null;

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
  DanmakuRemoteDataSource? get danmakuDataSource => null;

  @override
  VideoCommentRemoteDataSource? get videoCommentDataSource => null;

  @override
  VideoCommentRepliesRemoteDataSource? get videoCommentRepliesDataSource =>
      null;

  @override
  Future<void> close() async {}
}

List<VideoModel> _videos(int count) => List.generate(
  count,
  (i) => VideoModel(
    id: 'BV${i.toString().padLeft(2, '0')}',
    title: '第 ${i + 1} 个视频的标题文字',
    url: 'https://www.bilibili.com/video/BV$i',
    thumbnailUrl: 'https://example.com/thumb-$i.jpg',
    viewCount: 1000 * (i + 1),
    duration: 300 + i * 37,
  ),
);

Widget _homeScreenUnder({
  required int videoCount,
  required double width,
  required double height,
}) {
  final source = _FakeSource(count: videoCount);
  final bloc = HomeBloc(
    userDataRepository: _FakeUserDataRepository(),
    preferences: null,
    source: source,
  );

  return SizedBox(
    width: width,
    height: height,
    child: MultiProvider(
      providers: [
        Provider<MediaSourceCatalog>.value(
          value: MediaSourceCatalog([
            MediaSourceDefinition(
              id: source.id,
              name: source.name,
              create: () => source,
            ),
          ]),
        ),
        RepositoryProvider<MediaSource>.value(value: source),
        BlocProvider<HomeBloc>.value(value: bloc),
      ],
      child: HomeScreen(onLive: (_) {}, onVideo: (_) {}, onSettings: () {}),
    ),
  );
}

Widget _emptyHomeScreenUnder({required double width, required double height}) {
  final source = _FakeSource(count: 0);
  final bloc = HomeBloc(
    userDataRepository: _FakeUserDataRepository(),
    preferences: null,
    source: source,
  );

  return SizedBox(
    width: width,
    height: height,
    child: MultiProvider(
      providers: [
        Provider<MediaSourceCatalog>.value(
          value: MediaSourceCatalog([
            MediaSourceDefinition(
              id: source.id,
              name: source.name,
              create: () => source,
            ),
          ]),
        ),
        RepositoryProvider<MediaSource>.value(value: source),
        BlocProvider<HomeBloc>.value(value: bloc),
      ],
      child: HomeScreen(onLive: (_) {}, onVideo: (_) {}, onSettings: () {}),
    ),
  );
}

void main() {
  goldenTest(
    'renders full page structure',
    fileName: 'home_screen',
    pumpWidget: (tester, widget) async {
      await loadGoldenFont();
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            theme: goldenTestTheme(),
            home: Scaffold(body: Center(child: widget)),
          ),
        );
        await tester.pumpAndSettle();
      });
    },
    builder: () => GoldenTestGroup(
      columns: 1,
      children: [
        GoldenTestScenario(
          name: 'compact width, populated feed',
          child: _homeScreenUnder(videoCount: 3, width: 380, height: 800),
        ),
        GoldenTestScenario(
          name: 'medium width, populated feed',
          child: _homeScreenUnder(videoCount: 6, width: 700, height: 700),
        ),
        GoldenTestScenario(
          name: 'expanded width, populated feed',
          child: _homeScreenUnder(videoCount: 6, width: 960, height: 600),
        ),
        GoldenTestScenario(
          name: 'compact width, empty feed',
          child: _emptyHomeScreenUnder(width: 380, height: 400),
        ),
      ],
    ),
  );
}
