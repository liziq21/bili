import 'package:flutter/foundation.dart';

import 'package:logging/logging.dart';

import '../../data/model/user_data.dart';
import '../../data/repository/user_data/user_data_repository.dart';
import '../../utils/command.dart';
import '../../utils/result.dart';

class ThemeViewModel {
  ThemeViewModel({
    required UserDataRepository userDataRepository,
  }) : _userDataRepository = userDataRepository {
    load = Command0(_load)..execute();
    loadThemeConfig = Command0(_loadThemeConfig);
    loadDynamicColor = Command0(_loadDynamicColor);
    setThemeConfig = Command1(_setThemeConfig);
    setDynamicColor = Command1(_setDynamicColor);
  }
  
  final _log = Logger('ThemeViewModel');
  final UserDataRepository _userDataRepository;
  
  bool _useDynamicColor = false;
  ThemeConfig _themeConfig = .followSystem;
  
  bool get useDynamicColor => _useDynamicColor;
  ThemeConfig get themeConfig => _themeConfig;
  
  late final Command0 load;
  late final Command0 loadThemeConfig;
  late final Command0 loadDynamicColor;
  late final Command1 setThemeConfig;
  late final Command1 setDynamicColor;
  
  Future<Result<void>> _setThemeConfig(themeConfig) {
    _log.fine('Setting ThemeConfig');
    return _userDataRepository.setThemeConfig(themeConfig).then(
      () {
        _log.fine('ThemeConfig set successfully');
        loadThemeConfig.execute();
        return .ok(null);
      },
      onError: (e) {
        _log.warning('Failed to set ThemeConfig', e);
        return .error(Exception('$e'));
      },
    );
  }
  
  Future<Result<void>> _setDynamicColor(bool useDynamicColor) {
    _log.fine('Setting DynamicColor');
    return _userDataRepository.setDynamicColorPreference(useDynamicColor).then(
      () {
        _log.fine('DynamicColor set successfully');
        loadDynamicColor.execute();
        return .ok(null);
      },
      onError: (e) {
        _log.warning('Failed to set DynamicColor', e);
        return .error(Exception('$e'));
      },
    );
  }
  
  Future<Result<void>> _load() async {
    final results = await Future.wait(_loadThemeConfig, _loadDynamicColor);
    return const .ok(null);
  }
  
  Future<Result<void>> _loadThemeConfig() {
    _log.fine('Loading ThemeConfig');
    return _userDataRepository.themeConfig.then(
      (value) {
        if (value != null) {
          themeConfig = value;
        }
        _log.fine('ThemeConfig loaded');
        return .ok(null);
      },
      onError: (e) {
        _log.warning('Failed to load ThemeConfig', e);
        return .error(Exception('$e'));
      },
    );
  }
  
  Future<Result<void>> _loadDynamicColor() {
    _log.fine('Loading dynamic color');
    return _userDataRepository.dynamicColorPreference.then(
      (value) {
        if (value != null) {
          useDynamicColor = value;
        }
        _log.fine('Dynamic color loaded');
        return .ok(null);
      },
      onError: (e) {
        _log.warning('Failed to load dynamic color', e);
        return .error(Exception('$e'));
      },
    );
  }
}
