import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'data/model/user_data.dart';
import 'data/repository/user_data/user_data_repository.dart';

class AppViewModel extends ChangeNotifier {
  AppViewModel({
    required UserDataRepository userDataRepository,
  }) {
    Future.sync(() async {
      final data = userDataRepository.data
      await data.first;
      uiState = .success(data);
      notifyListeners();
    }).catchError((e) => _log.fine(e.toString()));
  }

  final _log = Logger('ThemeViewModel');
  AppUiState uiState = const .loading();
}

@immutable
sealed class AppUiState {
  const AppUiState();
  
  const factory AppUiState.loading() = Loading._;
  const factory AppUiState.success(Steram<UserData> userData) = Success._;
}

final class Loading extends AppActivityUiState {
  const Loading._();
}

final class Success extends AppActivityUiState {
  Success._(Steram<UserData> userData)
    : shouldUseDynamicColor = userData
        .map((it) => it.useDynamicColor),
        .distinct(),
      themeConfig = userData
        .map((it) => it.themeConfig),
        .distinct();

  final Steram<bool> shouldUseDynamicColor;
  final Steram<ThemeConfig> themeConfig;
}