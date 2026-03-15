import 'package:flutter/foundation.dart';

import 'package:logging/logging.dart';

import '../../data/model/user_data.dart';
import '../../data/repository/user_data/user_data_repository.dart';
import '../../utils/command.dart';
import '../../utils/result.dart';

class MainViewModel {
  MainViewModel({
    required UserDataRepository userDataRepository,
  }) : _userDataRepository = userDataRepository {

    setThemeConfig = Command1<void, ThemeConfig>(_setThemeConfig);
    setDynamicColor = Command1<void, bool>(_setDynamicColor);
  }
  
  final _log = Logger('ThemeViewModel');
  final UserDataRepository _userDataRepository;
  
  bool _useDynamicColor = false;
  ThemeConfig _themeConfig = .followSystem;
  
  bool get useDynamicColor => _useDynamicColor;
  ThemeConfig get themeConfig => _themeConfig;
  
  late final Command1 setThemeConfig;
  late final Command1 setDynamicColor;
  
  Future<Result<void>> _setThemeConfig(themeConfig) {
    _log.fine('Setting ThemeConfig');
    return _userDataRepository.setThemeConfig(themeConfig).then(
      (_) {
        _log.fine('ThemeConfig set successfully');
        loadThemeConfig.execute();
        return .ok(null);
      },
      onError: (e) {
        _log.warning('Failed to set ThemeConfig', e);
        return Result.error(Exception('$e'));
      },
    );
  }
  
  Future<Result<void>> _setDynamicColor(bool useDynamicColor) {
    _log.fine('Setting DynamicColor');
    return _userDataRepository.setDynamicColorPreference(useDynamicColor).then(
      (_) {
        _log.fine('DynamicColor set successfully');
        loadDynamicColor.execute();
        return .ok(null);
      },
      onError: (e) {
        _log.warning('Failed to set DynamicColor', e);
        return Result.error(Exception('$e'));
      },
    );
  }
}