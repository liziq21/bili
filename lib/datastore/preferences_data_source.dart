import 'dart:async';

//import 'package:logging/logging.dart';
import 'package:shared_pref/shared_pref.dart';

import '../utils/result.dart';

class PreferencesKey<T> {
  final String name;
  final T defaultValue;

  const PreferencesKey._(this.name, this.defaultValue);

  static const themeConfig = PreferencesKey<String>._('THEME_CONFIG', 'FOLLOW_SYSTEM');
  static const useDynamicColor = PreferencesKey<bool>._('USE_DYNAMIC_COLOR', true);
  
}

class PreferencesDataSource {
  PreferencesDataSource({
    required SharedPreferencesAysnc sharedPreferences,
  }) : _pref = sharedPreferences;
  
  final SharedPreferencesAysnc _pref;
  //final _log = Logger('PreferencesDataSource');
  
  static const _useDynamicColorKey = 'USE_DYNAMIC_COLOR';
  static const _themeConfigKey = 'THEME_CONFIG';
  
  static const _useDynamicColor = true;
  static const _themeConfig = 'FOLLOW_SYSTEM';
  
  Future<Result<T>> get<T>(PreferencesKey<T> key) {
    try {
      if (T == String) {
        return .ok(await _pref.getString(key.name) ?? key.defaultValue);
      } else if (T == bool) {
        return .ok(await _pref.getBool(key.name) ?? key.defaultValue);
      } else if (T == int) {
        return .ok(await _pref.getInt(key.name) ?? key.defaultValue);
      } else if (T == double) {
        return .ok(await _pref.getDouble(key.name) ?? key.defaultValue);
      } else if (T == List<String>) {
        return .ok(await _pref.getStringList(key.name) ?? key.defaultValue);
      }
      return .error(Exception('Unsupported type for SharedPreferences: $T'));
    } on Exception catch (e) {
      return .error(e);
    }
  }

  Future<Result<T>> set<T>(PreferencesKey<T> key, T value) async {
    try {
      if (value is String) {
        await _pref.setString(key.name, value);
      } else if (value is bool) {
        await _pref.setBool(key.name, value));
      } else if (value is int) {
        await _pref.setInt(key.name, value));
      } else if (value is double) {
        await _pref.setDouble(key.name, value));
      } else if (value is List<String>) {
        await _pref.setStringList(key.name, value));
      } else {
        return .error(Exception(
          'Unsupported type for SharedPreferences: ${value.runtimeType}'));
      }
      return .ok(value);
    } on Exception catch (e) {
      return .error(e);
    }
  }
  
  Future<bool> get dynamicColorPreference async {
    return (await _pref.getBool(_useDynamicColorKey)) ?? _useDynamicColor;
  }
  
  Future<String> get themeConfig async {
    return (await _pref.getString(_themeConfigKey)) ?? _themeConfig;
  }
  
  Future<void> setDynamicColorPreference(bool useDynamicColor) {
    return _pref.setBool(_useDynamicColorKey, useDynamicColor);
  }
  
  Future<void> setThemeConfig(String themeConfig) {
    return _pref.setString(_themeConfigKey, themeConfig);
  }
}