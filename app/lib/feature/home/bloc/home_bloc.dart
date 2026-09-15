import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:model/model.dart';

import '../../../data/repository/user_data/user_data_repository.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc({required final UserDataRepository userDataRepository})
    extends Bloc<HomeEvent, HomeState> {
  this : _userDataRepository = userDataRepository, super(const HomeState()) {
    on<MonitorUserData>(_onMonitorUserData);
    on<ServiceSourceChanged>(_onServiceSourceChanged);

    add(MonitorUserData());
  }

  final UserDataRepository _userDataRepository;
  final _log = Logger('HomeBloc');

  Future<void> _onMonitorUserData(
    MonitorUserData event,
    Emitter<HomeState> emit,
  ) async {
    await emit.forEach<UserData>(
      _userDataRepository.data,
      onData: (userData) =>
          state.copyWith(sourceId: userData.sourceId),
      onError: (error, stackTrace) {
        _log.warning('Failed to load user data in HomeBloc', error, stackTrace);
        return state;
      },
    );
  }

  Future<void> _onServiceSourceChanged(
    ServiceSourceChanged event,
    Emitter<HomeState> emit,
  ) async {
    if (event.sourceId == state.sourceId) return;
    _log.info('Changing service source to: ${event.sourceId}');
    await _userDataRepository.setSourceId(event.sourceId);
  }
}
