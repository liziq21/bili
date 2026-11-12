import 'dart:convert';

import 'package:app/data/repository/app_live_room_repository.dart';

import 'package:app/datastore/preferences_data_source.dart';
import 'package:app/feature/live/bloc/live_bloc.dart';

import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:model/model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// 直播房间数据源桩：记录调用、返回可配置结果。
class FakeLiveRoomDataSource() implements LiveRoomDetailRemoteDataSource {
  @override
  String get sourceId => 'fake';

  /// 最近一次 getLiveRoomStream 收到的 preferQn。
  int? lastPreferQn;

  /// getLiveRoomDetail 被调用的次数，用于验证后台刷新是否真的发生。
  int detailCalls = 0;

  /// getLiveRoomDetail 的返回值，测试可改（用于模拟刷新失败）。
  Result<LiveRoomDetail, Exception> Function(int roomId)? detailHandler;

  /// getLiveRoomStream 的返回值，测试可改。
  Result<MediaStream, Exception> streamResult = Result.success(
    MediaStream(
      videoUrl: 'https://example.com/live_150.m3u8',
      streamId: 150,
      qualityLabel: 'HD',
    ),
  );

  @override
  Future<Result<LiveRoomDetail, Exception>> getLiveRoomDetail(
    int roomId,
  ) async {
    detailCalls++;
    final handler = detailHandler;
    if (handler != null) return handler(roomId);
    return Result.success(
      LiveRoomDetail(
        roomId: roomId,
        title: 'Title',
        anchorName: 'Anchor',
        online: 100,
        isLive: true,
      ),
    );
  }

  @override
  Future<Result<MediaStream, Exception>> getLiveRoomStream(
    int roomId, {
    int? preferQn,
  }) async {
    lastPreferQn = preferQn;
    return streamResult;
  }
}

/// 在 testWidgets 的 fake-async zone 里显式推进事件队列，
/// 避免 `pumpEventQueue()` 在某些 Flutter 版本上挂死（见 flutter-bloc-widget-test-zones skill）。
Future<void> _pumpEventQueue(WidgetTester tester) async {
  await tester.pump();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('SwitchLiveQuality requests the target qn and swaps the stream', (
    tester,
  ) async {
    final dataSource = FakeLiveRoomDataSource();
    final newStream = MediaStream(
      videoUrl: 'https://example.com/live_250.m3u8',
      streamId: 250,
      qualityLabel: 'FHD',
    );
    dataSource.streamResult = Result.success(newStream);
    final bloc = LiveBloc(repository: AppLiveRoomRepository(dataSource));
    addTearDown(bloc.close);

    bloc.add(SwitchLiveQuality(21144080, 250));
    await _pumpEventQueue(tester);

    expect(dataSource.lastPreferQn, 250);
    expect(bloc.state.mediaStream, newStream);
    expect(bloc.state.isSwitchingQuality, isFalse);
  });

  testWidgets('Initial load requests the remembered quality for the room', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final pref = SharedPreferencesAsync();
    final preferences = PreferencesDataSource(sharedPreferences: pref);
    await preferences.set(
      PreferencesKey.liveQualityByRoom,
      jsonEncode({'21144080': 250}),
    );
    final dataSource = FakeLiveRoomDataSource();
    final bloc = LiveBloc(
      repository: AppLiveRoomRepository(dataSource),
      preferences: preferences,
    );
    addTearDown(bloc.close);

    bloc.add(LoadLiveStream(21144080));
    await _pumpEventQueue(tester);

    expect(dataSource.lastPreferQn, 250);
  });

  testWidgets('A successful switch remembers the quality for the room', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final pref = SharedPreferencesAsync();
    final preferences = PreferencesDataSource(sharedPreferences: pref);
    final dataSource = FakeLiveRoomDataSource();
    final bloc = LiveBloc(
      repository: AppLiveRoomRepository(dataSource),
      preferences: preferences,
    );
    addTearDown(bloc.close);

    bloc.add(SwitchLiveQuality(21144080, 400));
    await _pumpEventQueue(tester);

    final result = await preferences.get<String>(
      PreferencesKey.liveQualityByRoom,
    );
    expect(result.isSuccess(), isTrue);
    final stored = switch (result) {
      Success(:final success) => success,
      _ => throw StateError('unreachable'),
    };
    expect(jsonDecode(stored), {'21144080': 400});
  });

  testWidgets('A failed switch keeps the old stream without an error state', (
    tester,
  ) async {
    final oldStream = MediaStream(
      videoUrl: 'https://example.com/old.m3u8',
      streamId: 150,
      qualityLabel: 'HD',
    );
    final dataSource = FakeLiveRoomDataSource();
    dataSource.streamResult = Result.success(oldStream);
    final bloc = LiveBloc(repository: AppLiveRoomRepository(dataSource));
    addTearDown(bloc.close);

    bloc.add(LoadLiveStream(21144080));
    await _pumpEventQueue(tester);
    expect(bloc.state.mediaStream, oldStream);

    dataSource.streamResult = Result.error(Exception('boom'));
    bloc.add(SwitchLiveQuality(21144080, 250));
    await _pumpEventQueue(tester);

    expect(bloc.state.mediaStream, oldStream);
    expect(bloc.state.streamError, isNull);
    expect(bloc.state.isSwitchingQuality, isFalse);
  });

  group('LiveBloc room detail refresh', () {
    // 刷新用 Timer 驱动，而 testWidgets 的 fake-async zone 在测试结束时
    // 会校验「没有待处理的 Timer」——周期 Timer 只要没被 close 取消就无法
    // 通过。这里用纯 fake_async zone，可以随意推进时钟，且不要求取消。
    LiveBloc createBloc(
      FakeLiveRoomDataSource dataSource, {
      Duration? interval = const Duration(seconds: 5),
    }) {
      final bloc = LiveBloc(
        repository: AppLiveRoomRepository(dataSource),
        roomDetailRefreshInterval: interval,
      );
      addTearDown(bloc.close);
      return bloc;
    }

    void addAndFlush(FakeAsync async, LiveBloc bloc, LiveEvent event) {
      bloc.add(event);
      async.flushMicrotasks();
    }

    test('refreshes the room detail periodically after the first load', () {
      fakeAsync((async) {
        final dataSource = FakeLiveRoomDataSource();
        dataSource.detailHandler = (roomId) => Result.success(
          LiveRoomDetail(
            roomId: roomId,
            title: 'Title',
            anchorName: 'Anchor',
            online: dataSource.detailCalls * 100,
            isLive: true,
          ),
        );
        final bloc = createBloc(dataSource);

        addAndFlush(async, bloc, const LoadLiveRoomDetail(21144080));
        expect(bloc.state.roomDetail?.online, 100);

        async.elapse(const Duration(seconds: 5));

        expect(dataSource.detailCalls, 2);
        expect(bloc.state.roomDetail?.online, 200);
        expect(bloc.state.roomError, isNull);

        async.elapse(const Duration(seconds: 5));
        expect(dataSource.detailCalls, 3);
        expect(bloc.state.roomDetail?.online, 300);
      });
    });

    test('a failed refresh keeps the last detail and no error state', () {
      fakeAsync((async) {
        final dataSource = FakeLiveRoomDataSource();
        final bloc = createBloc(dataSource);

        addAndFlush(async, bloc, const LoadLiveRoomDetail(21144080));
        final loaded = bloc.state.roomDetail;
        expect(loaded?.online, 100);

        dataSource.detailHandler = (_) =>
            Result.error(Exception('rate limited'));
        async.elapse(const Duration(seconds: 5));

        expect(dataSource.detailCalls, 2, reason: 'the refresh must have run');
        expect(bloc.state.roomDetail, same(loaded));
        expect(bloc.state.roomError, isNull);
        expect(bloc.state.isLoading, isFalse);
      });
    });

    test('a failed first load does not start the refresh timer', () {
      fakeAsync((async) {
        final dataSource = FakeLiveRoomDataSource();
        dataSource.detailHandler = (_) => Result.error(Exception('offline'));
        final bloc = createBloc(dataSource);

        addAndFlush(async, bloc, const LoadLiveRoomDetail(21144080));
        expect(bloc.state.roomError, isNotNull);

        async.elapse(const Duration(minutes: 5));

        expect(dataSource.detailCalls, 1);
      });
    });

    test('interval null disables the refresh', () {
      fakeAsync((async) {
        final dataSource = FakeLiveRoomDataSource();
        final bloc = createBloc(dataSource, interval: null);

        addAndFlush(async, bloc, const LoadLiveRoomDetail(21144080));
        async.elapse(const Duration(minutes: 5));

        expect(dataSource.detailCalls, 1);
      });
    });
  });
}
