import '../../../utils/result.dart';
import '../../model/user_data.dart';

abstract class UserDataRepository {
  
  Future<Result<bool>> dynamicColorPreference();
  
  Future<Result<ThemeConfig>> themeConfig();

  Future<Result<void>> setThemeConfig(ThemeConfig themeConfig);

  Future<Result<void>> setDynamicColorPreference(bool useDynamicColor);
  
}