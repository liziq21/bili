import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'data/model/user_data.dart';
import 'data/repository/user_data/user_data_repository.dart';
import 'utils/command.dart';
import 'utils/utils.dart';

class AppViewModel {
  AppViewModel({
    UserDataRepository userDataRepository
  }) : _userDataRepository = userDataRepository {
    _loadUserData();
  };
  
  final _log = Logger('AppViewModel');
  late final UserDataRepository _userDataRepository;
  AppUiState _uiState = .loading();
  var isInitialLoading = true;
  
  AppUiState get uiState async {
    if (!isInitialLoading) {
      await _loadUserData();
    } else if (_uiState case Success()) {
      _log.info('Initial loading of AppUiState successful');
      isInitialLoading = false;
    }
    return _uiState;
  }
  
  Future<void> _loadUserData() async {
    final result = await _userDataRepository.userData;
    switch (result) {
      case Ok(:value):
        _uiState = .success(value);
      case Error():
    }
  }
}

sealed class AppUiState {
  
  const factory AppUiState.loading() = Loading._;
  
  const factory AppUiState.success(UserData userData) = Success._;
  
  bool get shouldKeepSplashScreen => this is Loading;
  
  bool get shouldDisableDynamicTheming => true;

  ThemeMode get shouldUseDarkTheme(isSystemDarkTheme: Boolean) => .system;
  
}

final class Success extends AppUiState {
  const Success._(this.userData);

  final UserData userData;
  
  @override
  bool get shouldDisableDynamicTheming = !userData.useDynamicColor;

  @override
  ThemeMode get shouldUseDarkTheme(isSystemDarkTheme: Boolean) =>
    switch (userData.darkThemeConfig) {
      .followSystem => .system,
      .light => .light,
      .dark => .dark,
    };
}

final class Loading extends AppUiState {
  const Loading._();
}