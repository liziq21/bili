import 'package:flutter/foundation.dart';

import '../../../utils/result.dart';
import '../../model/user_data.dart';

abstract class UserDataRepository {
  
  Future<ValueNotifier<bool>> get dynamicColorPreference;
  Future<ValueNotifier<ThemeConfig>> get themeConfig;

  Future<void> setThemeConfig(ThemeConfig themeConfig);

  Future<void> setDynamicColorPreference(bool useDynamicColor);
  
}