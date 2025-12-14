import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesDataSource {
  const PreferencesDataSource({
    SharedPreferencesAsync userPreferences = new(),
  }) : _userPreferences = userPreferences;
  
  late final _userPreferences;
  Map<String, dynamic> get userData => _preferences.getAll();
  
  Future<void> setDarkThemeConfig(String darkThemeConfig) async =>
    userPreferences.setString('darkThemeConfig', darkThemeConfig);

  Future<void> setDynamicColorPreference(bool useDynamicColor) async =>
    userPreferences.setBool('useDynamicColor', useDynamicColor);

}