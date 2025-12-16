import 'dart:async';

import '../../../datastore/preferences_data_source.dart';
import '../../model/user_data.dart';
import 'user_data_repository.dart';

class DefaultUserDataRepository implements UserDataRepository {
  DefaultUserDataRepository({
    required PreferencesDataSource preferencesDataSource,
  }) : _preferencesDataSource = preferencesDataSource;
  
  late final PreferencesDataSource _preferencesDataSource;
  
  @override
  Future<UserData> getUserData() async =>
    UserData.fromJson(await _preferencesDataSource.getUserData());
  
  @override
  Future<void> setDarkThemeConfig(DarkThemeConfig darkThemeConfig) async =>
    await _preferencesDataSource.setDarkThemeConfig(darkThemeConfig.toString());

  @override
  Future<void> setDynamicColorPreference(bool useDynamicColor) async =>
    await _preferencesDataSource.setDynamicColorPreference(useDynamicColor);
  
}