import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'data/model/user_data.dart';
import 'data/repository/user_data/user_data_repository.dart';
import 'utils/command.dart';
import 'utils/result.dart';

class AppViewModel {
  AppViewModel({
    required UserDataRepository userDataRepository,
  }) : _userDataRepository = userDataRepository {
    _load = Command0(_loadData)..execute();
  };
  
  final _log = Logger('AppViewModel');
  final UserDataRepository _userDataRepository;
  
  late final Command0 _load;
  
  late final ValueNotifier<bool> useDynamicColor;
  late final ValueNotifier<ThemeConfig> themeConfig;
  
  bool get shouldKeepSplashScreen => _load.running ?? true;
  bool get shouldUseDynamicTheming => _load.running ? false : useDynamicColor.value;
  ThemeMode get themeMode => _load.running 
    ? .system
    : switch (themeConfig.value) {
        .followSystem => .system,
        .light => .light,
        .dark => .dark,
      };
  
  Future<Result<void>> _loadData() async {
    try {
      useDynamicColor = await _userDataRepository.dynamicColorPreference;
      themeConfig = await _userDataRepository.themeConfig;
    } catch (e) {
      return .error(Exception('$e'));
    }

    return .ok(null);
  }
}
