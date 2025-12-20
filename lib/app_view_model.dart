import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'data/model/user_data.dart';
import 'data/repository/user_data/user_data_repository.dart';
import 'utils/command.dart';
import 'utils/result.dart';

class AppViewModel {
  const AppViewModel({
    required UserDataRepository userDataRepository,
  }) : _userDataRepository = userDataRepository {
    _load = Command0(_load)..execute();
  };
  
  final _log = Logger('AppViewModel');
  final UserDataRepository _userDataRepository;
  
  late final Command0 _load;
  
  late final ValueNotifier<bool> useDynamicColor;
  late final ValueNotifier<ThemeConfig> themeConfig;
  
  bool get shouldKeepSplashScreen => _load.running ?? true;
  bool get shouldUseDynamicTheming => _load.running ?? useDynamicColor.value ?? false;
  ThemeMode get themeMode => _load.running ? .system : switch (themeConfig.value) {
    .followSystem || null => .system,
    .light => .light,
    .dark => .dark,
  };
  
  Future<Result<void>> _load() async {
    try {
      useDynamicColor = await _userDataRepository.dynamicColorPreference;
      themeConfig = await _userDataRepository.themeConfig;
    } catch (e) {
      return .error('$e');
    }

    return .ok(null);
  }
}
