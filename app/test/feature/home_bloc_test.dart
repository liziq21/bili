import 'dart:async';

import 'package:app/data/repository/user_data/user_data_repository.dart';
import 'package:app/feature/home/bloc/home_bloc.dart';
import 'package:app/feature/home/home_screen.dart';
import 'package:app/providers/media_sources_provider.dart';
import 'package:data/data.dart';
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

void main() {
  group('HomeBloc Tests', () {
    late MockUserDataRepository mockUserDataRepository;
    late HomeBloc homeBloc;

    setUp(() {
      mockUserDataRepository = MockUserDataRepository();
      homeBloc = HomeBloc(userDataRepository: mockUserDataRepository);
    });

    tearDown(() {
      homeBloc.close();
      mockUserDataRepository.dispose();
    });

    test('Initial state is default HomeState', () {
      expect(
        homeBloc.state,
        const HomeState(sourceId: 'bilibili'),
      );
    });

    test('Emits updated sourceId when UserData changes', () async {
      mockUserDataRepository.emitData(
        const UserData(sourceId: 'youtube'),
      );

      await expectLater(
        homeBloc.stream,
        emits(const HomeState(sourceId: 'youtube')),
      );
    });

    test(
      'ServiceSourceChanged event triggers repository setSourceId',
      () async {
        homeBloc.add(ServiceSourceChanged('youtube'));

        await expectLater(
          homeBloc.stream,
          emits(const HomeState(sourceId: 'youtube')),
        );
      },
    );
  });

  group('HomeScreen Widget Tests', () {
    late MockUserDataRepository mockUserDataRepository;
    late HomeBloc homeBloc;

    setUp(() {
      mockUserDataRepository = MockUserDataRepository();
      homeBloc = HomeBloc(userDataRepository: mockUserDataRepository);
    });

    tearDown(() {
      homeBloc.close();
      mockUserDataRepository.dispose();
    });

    testWidgets('Renders DropdownButton with Bilibili initially', (
      tester,
    ) async {
      await tester.pumpWidget(
        Provider<List<MediaSource>>.value(
          value: defaultMediaSources,
          child: MaterialApp(
            home: BlocProvider<HomeBloc>.value(
              value: homeBloc,
              child: HomeScreen(
                onLive: (_) {},
                navigateToSearchReault: (_) {},
                onSpace: (_) {},
                onVideo: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Bilibili'), findsOneWidget);
    });
  });
}
