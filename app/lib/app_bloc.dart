import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:model/model.dart';

import 'data/repository/user_data/user_data_repository.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc({
    required UserDataRepository userDataRepository,
  })  : _userDataRepository = userDataRepository,
        super(Loading()) {
    on<AppStarted>(_onStarted);
    add(AppStarted());
  }

  final UserDataRepository _userDataRepository;
  final _log = Logger('AppBloc');

  Future<void> _onStarted(AppStarted event, Emitter<AppState> emit) async {
    await emit.forEach<UserData>(
      _userDataRepository.data,
      onData: (data) => LoadSuccess(data),
      onError: (error, stackTrace) {
        _log.warning('Failed to load user data', error, stackTrace);
        return LoadFailure(error);
      },
    );
  }
}

sealed class AppEvent {}

class AppStarted extends AppEvent {}

sealed class AppState {}

class LoadFailure extends AppState {
  LoadFailure(this.error);
  final Object error;
}

class Loading extends AppState {}

class LoadSuccess extends AppState {
  LoadSuccess(this.userData);
  final UserData userData;
}
