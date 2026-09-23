import 'dart:async';

import 'package:app/app.dart';
import 'package:app/app_bloc.dart';
import 'package:app/app_scaffold.dart';
import 'package:app/data/repository/user_data/user_data_repository.dart';
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
      final userDataRepository = FakeUserDataRepository();
      final appBloc = AppBloc(userDataRepository: userDataRepository);
      final mediaSources = <MediaSource>[
        FakeMediaSource('bilibili', 'Bilibili'),
      ];

      addTearDown(() {
        appBloc.close();
        userDataRepository.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: RepositoryProvider<UserDataRepository>.value(
            value: userDataRepository,
            child: BlocProvider<AppBloc>.value(
              value: appBloc,
              child: Provider<List<MediaSource>>.value(
                value: mediaSources,
                child: const App(),
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
