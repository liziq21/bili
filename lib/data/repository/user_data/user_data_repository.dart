import '../../../utils/result.dart';
import '../../model/user_data.dart';

abstract class UserDataRepository {
  
  Future<bool?> get dynamicColorPreference;
  Future<ThemeConfig?> get themeConfig;

  Future<void> setThemeConfig(ThemeConfig themeConfig);

  Future<void> setDynamicColorPreference(bool useDynamicColor);
  
}