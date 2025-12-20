import 'dart:async';

import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/result.dart';

class PreferencesDataSource {
  PreferencesDataSource({
    required SharedPreferencesAsync sharedPreferences,
  }) : _sharedPreferences = sharedPreferences;
  
  final SharedPreferencesAsync _sharedPreferences;
  final _log = Logger('PreferencesDataSource');

  static const useDynamicColorKey = 'USE_DYNAMIC_COLOR';
  static const themeConfigKey = 'THEME_CONFIG';
  
  Future<bool?> get dynamicColorPreference async =>
    await _sharedPreferences.getBool(useDynamicColorKey);
  
  Future<String?> get themeConfig async =>
    await _sharedPreferences.getString(themeConfigKey);
  
  Future<void> setDynamicColorPreference(bool useDynamicColor) =>
    _sharedPreferences.setBool(useDynamicColorKey, useDynamicColor);

  Future<void> setThemeConfig(String themeConfig) =>
    _sharedPreferences.setString(themeConfigKey, themeConfig);

}