import 'package:flutter/foundation.dart';

import '../../../datastore/preferences_data_source.dart';
import '../../../utils/result.dart';
import '../../model/user_data.dart';
import 'user_data_repository.dart';

class DefaultUserDataRepository implements UserDataRepository {
  const DefaultUserDataRepository({
    required PreferencesDataSource preferencesDataSource,
  }) : _preferencesDataSource = preferencesDataSource;
  
  final PreferencesDataSource _preferencesDataSource;

  ValueNotifier<bool>? _dynamicColorPreference;
  ValueNotifier<ThemeConfig> _themeConfig;
  
  @override
  Future<ValueNotifier<bool>> get dynamicColorPreference async {
    _dynamicColorPreference ??= .new(await _preferencesDataSource.dynamicColorPreference);
    return _dynamicColorPreference!;
  }

  @override
  Future<ValueNotifier<ThemeConfig>> get themeConfig async {
    _themeConfig ??= .new(ThemeConfig.fromJson(await _preferencesDataSource.themeConfig));
    return _themeConfig!;
  }

  @override
  Future<void> setDynamicColorPreference(bool useDynamicColor) async {
    _preferencesDataSource.setDynamicColorPreference(useDynamicColor);
    _dynamicColorPreference?.value = useDynamicColor;
  }
  
  @override
  Future<void> setThemeConfig(ThemeConfig themeConfig) async {
    await _preferencesDataSource.setThemeConfig(themeConfig.toJson());
    _themeConfig?.value = themeConfig;
  }
}