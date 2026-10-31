import 'dart:convert';

import 'package:app/data/repository/app_live_room_repository.dart';

import 'package:app/datastore/preferences_data_source.dart';
import 'package:app/feature/live/bloc/live_bloc.dart';

import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
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
    await pumpEventQueue();

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
    await pumpEventQueue();

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
    await pumpEventQueue();

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
    await pumpEventQueue();
    expect(bloc.state.mediaStream, oldStream);

    dataSource.streamResult = Result.error(Exception('boom'));
    bloc.add(SwitchLiveQuality(21144080, 250));
    await pumpEventQueue();

    expect(bloc.state.mediaStream, oldStream);
    expect(bloc.state.streamError, isNull);
    expect(bloc.state.isSwitchingQuality, isFalse);
  });
}
