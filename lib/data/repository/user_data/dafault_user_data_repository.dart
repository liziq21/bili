import 'dart:async';

import '../../../datastore/preferences_data_source.dart';
import '../../model/user_data.dart';
import 'user_data_repository.dart';

class DefaultUserDataRepository implements UserDataRepository {
  const DefaultUserDataRepository({
    required PreferencesDataSource preferencesDataSource,
  }) : _preferencesDataSource = preferencesDataSource;
  
  late final PreferencesDataSource _preferencesDataSource;
  
  Future<UserData> getUserData() async =>
    UserData.fromJson(await _preferencesDataSource.getUserData());
  
  Future<void> setDarkThemeConfig(DarkThemeConfig darkThemeConfig) async =>
    await _preferencesDataSource.setDarkThemeConfig(darkThemeConfig.toString());

  Future<void> setDynamicColorPreference(bool useDynamicColor) async =>
    await _preferencesDataSource.setDynamicColorPreference(useDynamicColor);
  
}