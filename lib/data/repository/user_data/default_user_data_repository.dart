import '../../../datastore/preferences_data_source.dart';
import '../../../utils/result.dart';
import '../../model/user_data.dart';
import 'user_data_repository.dart';

class DefaultUserDataRepository implements UserDataRepository {
  DefaultUserDataRepository({
    required PreferencesDataSource preferencesDataSource,
  }) : _preferencesDataSource = preferencesDataSource;
  
  final PreferencesDataSource _preferencesDataSource;

  bool _dynamicColorPreference = false;
  ThemeConfig _themeConfig = .followSystem;
  
  @override
  Future<bool?> get dynamicColorPreference =>
    _preferencesDataSource.dynamicColorPreference;

  @override
  Future<ThemeConfig?> get themeConfig async {
    final preference = await _preferencesDataSource.themeConfig;
    return preference != null ? ThemeConfig.fromJson(preference) : null;
  }


  @override
  Future<void> setDynamicColorPreference(bool useDynamicColor) =>
    _preferencesDataSource.setDynamicColorPreference(useDynamicColor);
  
  @override
  Future<void> setThemeConfig(ThemeConfig themeConfig) =>
    _preferencesDataSource.setThemeConfig(themeConfig.toJson());
    
}