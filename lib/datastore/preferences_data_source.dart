import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesDataSource {
  late final _userPreferences = SharedPreferencesAsync();
  
  Future<Map<String, Object?>> getUserData() async =>
    await _userPreferences.getAll();
  
  Future<void> setDarkThemeConfig(String darkThemeConfig) async =>
    await _userPreferences.setString('darkThemeConfig', darkThemeConfig);

  Future<void> setDynamicColorPreference(bool useDynamicColor) async =>
    await _userPreferences.setBool('useDynamicColor', useDynamicColor);

}