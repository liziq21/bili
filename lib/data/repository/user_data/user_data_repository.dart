import 'dart:async';

import '../../model/user_data.dart';

abstract class UserDataRepository {
  
  Future<UserData> getUserData();

  Future<void> setDarkThemeConfig(DarkThemeConfig darkThemeConfig);

  Future<void> setDynamicColorPreference(bool useDynamicColor);
  
}