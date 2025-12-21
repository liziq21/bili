import '../../../datastore/preferences_data_source.dart';
import '../../../utils/result.dart';
import '../../model/user_data.dart';
import 'user_data_repository.dart';

class DefaultUserDataRepository implements UserDataRepository {
  DefaultUserDataRepository({
    required PreferencesDataSource preferencesDataSource,
  }) : _preferencesDataSource = preferencesDataSource;
  
  final PreferencesDataSource _preferencesDataSource;

  bool _dynamicColorPreference = .new(false);
  ThemeConfig _themeConfig = .new(.followSystem);
  
  @override
  Future<bool?> get dynamicColorPreference =>
    _preferencesDataSource.dynamicColorPreference;

  @override
  Future<ThemeConfig?> get themeConfig async {
    final preference = await _preferencesDataSource.themeConfig;
    return ThemeConfig.fromJson(preference);
  }


  @override
  Future<void> setDynamicColorPreference(bool useDynamicColor) =>
    _preferencesDataSource.setDynamicColorPreference(useDynamicColor);
  
  @override
  Future<void> setThemeConfig(ThemeConfig themeConfig) =>
    _preferencesDataSource.setThemeConfig(themeConfig.toJson());
    
}