import 'package:flutter/foundation.dart';

import '../../../datastore/preferences_data_source.dart';
import '../../../utils/result.dart';
import '../../model/user_data.dart';
import 'user_data_repository.dart';

class DefaultUserDataRepository implements UserDataRepository {
  DefaultUserDataRepository({
    required PreferencesDataSource preferencesDataSource,
  }) : _preferencesDataSource = preferencesDataSource;
  
  final PreferencesDataSource _preferencesDataSource;

  ValueNotifier<bool> _dynamicColorPreference = .new(false);
  ValueNotifier<ThemeConfig> _themeConfig = .new(.followSystem);
  
  @override
  Future<ValueNotifier<bool>> get dynamicColorPreference async {
    final preference = await _preferencesDataSource.dynamicColorPreference;
    if (preference != null) {
      _dynamicColorPreference.value = preference;
    }
    return _dynamicColorPreference;
  }

  @override
  Future<ValueNotifier<ThemeConfig>> get themeConfig async {
    final preference = await _preferencesDataSource.themeConfig;
    if (preference != null) {
      _themeConfig.value = ThemeConfig.fromJson(preference);
    }
    return _themeConfig;
  }

  @override
  Future<void> setDynamicColorPreference(bool useDynamicColor) async {
    _preferencesDataSource.setDynamicColorPreference(useDynamicColor);
    _dynamicColorPreference.value = useDynamicColor;
  }
  
  @override
  Future<void> setThemeConfig(ThemeConfig themeConfig) async {
    await _preferencesDataSource.setThemeConfig(themeConfig.toJson());
    _themeConfig.value = themeConfig;
  }
}