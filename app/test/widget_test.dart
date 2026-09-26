import 'dart:async';

import 'package:app/app.dart';
import 'package:app/app_bloc.dart';
import 'package:app/app_scaffold.dart';
import 'package:app/data/model/recent_search_query.dart';
import 'package:app/data/repository/recent_search_query/recent_search_query_repository.dart';
import 'package:app/data/repository/user_data/user_data_repository.dart';
import 'package:app/domain/get_recent_search_queries_use_case.dart';
import 'package:app/feature/home/home_screen.dart';
import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';
import 'package:provider/provider.dart';

class FakeUserDataRepository() implements UserDataRepository {
  this : _currentData = const UserData(sourceId: 'bilibili') {
    _controller.onListen = () {
      _controller.add(_currentData);
    };
  }

  final StreamController<UserData> _controller =
      StreamController<UserData>.broadcast();
  UserData _currentData;

  @override
  Stream<UserData> get data => _controller.stream;

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

/// 首页搜索入口（`HomeRouteData` 里的 `_withSearchBloc`）会 `read` 这个仓库来
/// 构造 `SearchBloc`。生产环境由 `main.dart` 的 `repoProviders` 提供，本测试
/// 之前没提供，于是 `SearchBloc` 一旦真的被创建就会抛
/// `ProviderNotFoundException`。
class const FakeRecentSearchQueryRepository()
    implements RecentSearchQueryRepository {
  @override
  Stream<List<RecentSearchQuery>> getRecentSearchQueries(int limit) =>
      const Stream.empty();

  @override
  Future<void> insertOrReplaceRecentSearch(String searchQuery) async {}

  @override
  Future<void> clearRecentSearchQueries() async {}
}

class FakeMediaSource(@override final String id, @override final String name)
    implements MediaSource {
  @override
  final List<VideoFeedRemoteDataSource> videoFeedDataSources = const [];
  @override
  final List<LiveRoomFeedRemoteDataSource> liveRoomFeedDataSources = const [];
  @override
  final LiveRoomSearchRemoteDataSource? liveRoomSearchDataSource = null;

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
  testWidgets(
    'App start smoke test: initializes core assembly and displays home screen',
    (tester) async {
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        final msg = details.toString();
        if (msg.contains('MaterialLocalizations') ||
            msg.contains('CupertinoLocalizations') ||
            msg.contains('localization delegates') ||
            msg.contains('locale')) {
          return;
        }
        oldOnError?.call(details);
      };

      final userDataRepository = FakeUserDataRepository();
      final appBloc = AppBloc(userDataRepository: userDataRepository);
      final mediaSources = <MediaSource>[
        FakeMediaSource('bilibili', 'Bilibili'),
      ];

      addTearDown(() {
        FlutterError.onError = oldOnError;
        appBloc.close();
        userDataRepository.dispose();
      });

      // 顺序对齐 `main.dart`：仓库在 bloc 和 MediaSource 之外层。
      final recentSearchQueryRepository = FakeRecentSearchQueryRepository();

      await tester.pumpWidget(
        RepositoryProvider<UserDataRepository>.value(
          value: userDataRepository,
          child: RepositoryProvider<RecentSearchQueryRepository>.value(
            value: recentSearchQueryRepository,
            child: RepositoryProvider<GetRecentSearchQueriesUseCase>.value(
              value: GetRecentSearchQueriesUseCase(
                recentSearchQueryRepository: recentSearchQueryRepository,
              ),
              child: BlocProvider<AppBloc>.value(
                value: appBloc,
                child: Provider<List<MediaSource>>.value(
                  value: mediaSources,
                  child: const App(),
                ),
              ),
            ),
          ),
        ),
      );

      // Pump to trigger AppBloc state change from Loading to LoadSuccess and render MaterialApp.router
      await tester.pump();

      expect(find.byType(AppScaffold), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);
    },
  );
}
