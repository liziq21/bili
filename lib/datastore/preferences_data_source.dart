import 'dart:async';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/result.dart';

class PreferencesDataSource {
  static const _themeConfig = 'THEME_CONFIG';
  static const _useDynamicColor = 'USE_DYNAMIC_COLOR';
  final _log = Logger('PreferencesDataSource');


  Future<Result<Map<String, Object?>>> getUserData() async {
    try {
      _log.finer('getUserData');
      return .ok(await SharedPreferencesAsync().getAll());
    } on Exception catch (e) {
      _log.warning('Failed to getUserData', e);
      return .error(e);
    }
  }
  
  Future<Result<void>> setThemeConfig(String themeConfig) async =>
    _set(_themeConfig, (it) => it.setString(_themeConfig, themeConfig));

  Future<Result<void>> setDynamicColorPreference(bool useDynamicColor) async =>
    _set(_useDynamicColor, (it) => it.setBool(_useDynamicColor, useDynamicColor));
  
  Future<Result<void>> _set(String name, Future<void> Function(SharedPreferencesAsync) setPref) {
    try {
      _log.finer('Set $name');
      await setPref(SharedPreferencesAsync());
      return const .ok(null);
    } on Exception catch (e) {
      _log.warning('Failed to set $name', e);
      return .error(e);
    }
  }
}