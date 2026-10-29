import 'dart:async';

import 'package:data/data.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:model/model.dart';

import '../../../data/repository/app_live_room_repository.dart';

part 'live_event.dart';
part 'live_state.dart';

class LiveBloc({required final AppLiveRoomRepository _repository})
    extends Bloc<LiveEvent, LiveState> {
  this : super(const LiveState()) {
    on<LoadLiveRoomDetail>(_onLoadLiveRoomDetail);
    on<LoadLiveStream>(_onLoadLiveStream);
  }

  final _log = Logger('LiveBloc');

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
      case Error(:final error):
        _log.warning('Failed to load live room detail', error);
        emit(state.copyWith(isLoading: false, roomError: error.toString()));
    }
  }

  Future<void> _onLoadLiveStream(
    LoadLiveStream event,
    Emitter<LiveState> emit,
  ) async {
    emit(state.copyWith(streamError: null));
    _log.info('Loading live stream for room: ${event.roomId}');

    final result = await _repository.getLiveRoomStream(event.roomId);
    switch (result) {
      case Success(:final success):
        emit(state.copyWith(mediaStream: success));
      case Error(:final error):
        _log.warning('Failed to load live stream', error);
        emit(state.copyWith(streamError: error.toString()));
    }
  }
}
