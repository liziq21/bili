import 'dart:async';
import 'dart:convert';

import 'package:data/data.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:model/model.dart';

import '../../../data/repository/app_live_room_repository.dart';
import '../../../datastore/preferences_data_source.dart';

part 'live_event.dart';
part 'live_state.dart';

class LiveBloc({
  required final AppLiveRoomRepository _repository,
  final PreferencesDataSource? _preferences,

  /// 直播间详情（在线人数、标题）的后台刷新间隔。
  ///
  /// null 关闭刷新；测试可注入短间隔，默认 [defaultRoomDetailRefreshInterval]。
  final Duration? roomDetailRefreshInterval = defaultRoomDetailRefreshInterval,
}) extends Bloc<LiveEvent, LiveState> {
  this : super(const LiveState()) {
    on<LoadLiveRoomDetail>(_onLoadLiveRoomDetail);
    on<RefreshLiveRoomDetail>(_onRefreshLiveRoomDetail);
    on<LoadLiveStream>(_onLoadLiveStream);
    on<SwitchLiveQuality>(_onSwitchLiveQuality);
  }

  /// 在线人数是分钟级的展示信息，30 秒足够跟上变化，又不会把
  /// roomInfo 端点刷成负担。
  static const defaultRoomDetailRefreshInterval = Duration(seconds: 30);

  final _log = Logger('LiveBloc');
  Timer? _roomDetailRefreshTimer;

  /// 首次加载之后启动定时刷新；关闭刷新或首次加载失败时不起定时器
  /// （失败态由用户点重试，不自动重试）。
  void _startRoomDetailRefresh(int roomId) {
    _roomDetailRefreshTimer?.cancel();
    final interval = roomDetailRefreshInterval;
    if (interval == null) return;
    _roomDetailRefreshTimer = Timer.periodic(
      interval,
      (_) => add(RefreshLiveRoomDetail(roomId)),
    );
  }

  Future<void> _onLoadLiveRoomDetail(
    LoadLiveRoomDetail event,
    Emitter<LiveState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, roomError: null));
    _log.info('Loading live room detail for room: ${event.roomId}');

    final result = await _repository.getLiveRoomDetail(event.roomId);
    switch (result) {
      case Success(:final success):
        emit(state.copyWith(isLoading: false, roomDetail: success));
        _startRoomDetailRefresh(event.roomId);
      case Error(:final error):
        _log.warning('Failed to load live room detail', error);
        _roomDetailRefreshTimer?.cancel();
        emit(state.copyWith(isLoading: false, roomError: error.toString()));
    }
  }

  /// 后台刷新：成功才替换详情；失败保留旧值，不进入错误态、不改加载态。
  Future<void> _onRefreshLiveRoomDetail(
    RefreshLiveRoomDetail event,
    Emitter<LiveState> emit,
  ) async {
    final result = await _repository.getLiveRoomDetail(event.roomId);
    switch (result) {
      case Success(:final success):
        emit(state.copyWith(roomDetail: success));
      case Error(:final error):
        _log.fine('Failed to refresh live room detail', error);
    }
  }

  @override
  Future<void> close() {
    _roomDetailRefreshTimer?.cancel();
    _roomDetailRefreshTimer = null;
    return super.close();
  }

  Future<void> _onLoadLiveStream(
    LoadLiveStream event,
    Emitter<LiveState> emit,
  ) async {
    emit(state.copyWith(streamError: null));
    _log.info('Loading live stream for room: ${event.roomId}');

    // 记住的清晰度优先：重新进入房间直接请求上次那档，避免先开默认档
    // 再切一次的多余重开。
    final rememberedQn = await _readRememberedQn(event.roomId);
    final result = await _repository.getLiveRoomStream(
      event.roomId,
      preferQn: rememberedQn,
    );
    switch (result) {
      case Success(:final success):
        emit(state.copyWith(mediaStream: success));
      case Error(:final error):
        _log.warning('Failed to load live stream', error);
        emit(state.copyWith(streamError: error.toString()));
    }
  }

  Future<void> _onSwitchLiveQuality(
    SwitchLiveQuality event,
    Emitter<LiveState> emit,
  ) async {
    emit(state.copyWith(isSwitchingQuality: true));
    _log.info(
      'Switching live quality for room: ${event.roomId} to qn ${event.qn}',
    );

    final result = await _repository.getLiveRoomStream(
      event.roomId,
      preferQn: event.qn,
    );
    switch (result) {
      case Success(:final success):
        // 换流重开由渲染层监听 mediaStream 变化触发；失败不换错误态，
        // 旧流地址仍在播放，继续用它。
        await _persistRememberedQn(event.roomId, event.qn);
        emit(state.copyWith(mediaStream: success, isSwitchingQuality: false));
      case Error(:final error):
        _log.warning('Failed to switch live quality', error);
        emit(state.copyWith(isSwitchingQuality: false));
    }
  }

  /// 读每房间记住的直播清晰度。读失败或无记忆时返回 null（源取默认档）。
  Future<int?> _readRememberedQn(int roomId) async {
    if (_preferences == null) return null;
    try {
      final result = await _preferences.get<String>(
        PreferencesKey.liveQualityByRoom,
      );
      switch (result) {
        case Success(:final success):
          final rooms = jsonDecode(success) as Map<String, dynamic>;
          final qn = rooms[roomId.toString()];
          return qn is int ? qn : null;
        case Error():
          return null;
      }
    } catch (_) {
      return null;
    }
  }

  /// 把选中的清晰度记为该房间的上次选择。
  Future<void> _persistRememberedQn(int roomId, int qn) async {
    if (_preferences == null) return;
    try {
      final current = await _preferences.get<String>(
        PreferencesKey.liveQualityByRoom,
      );
      final rooms = switch (current) {
        Success(:final success) => jsonDecode(success) as Map<String, dynamic>,
        Error() => <String, dynamic>{},
      };
      rooms[roomId.toString()] = qn;
      await _preferences.set(
        PreferencesKey.liveQualityByRoom,
        jsonEncode(rooms),
      );
    } catch (_) {}
  }
}
