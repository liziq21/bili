import 'dart:async';

import '../../../datastore/preferences_data_source.dart';
import '../../model/user_data.dart';
import 'user_data_repository.dart'

class DefaultUserDataRepository implements UserDataRepository {
  const DefaultUserDataRepository({
    required PreferencesDataSource preferencesDataSource,
  }) : _preferencesDataSource = preferencesDataSource;
  
  lata final PreferencesDataSource _preferencesDataSource
  lata final _userData = UserData.fromJson(_preferencesDataSource.userData);
  Future<UserData> get userData => _userData;

  Future<void> setDarkThemeConfig(DarkThemeConfig darkThemeConfig) =>
    _preferencesDataSource.setDarkThemeConfig(darkThemeConfig.toString);

  Future<void> setDynamicColorPreference(bool useDynamicColor) =>
    _preferencesDataSource.setDynamicColorPreference(useDynamicColor);
  
}