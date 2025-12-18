import '../../../datastore/preferences_data_source.dart';
import '../../../utils/result.dart';
import '../../model/user_data.dart';
import 'user_data_repository.dart';

class DefaultUserDataRepository implements UserDataRepository {
  DefaultUserDataRepository({
    required PreferencesDataSource preferencesDataSource,
  }) : _preferencesDataSource = preferencesDataSource;
  
  late final PreferencesDataSource _preferencesDataSource;

  @override
  Future<Result<UserData>> get userData async =>
    (await _preferencesDataSource.getUserData()).map(UserData.fromJson);
  
  @override
  Future<Result<void>> setThemeConfig(ThemeConfig themeConfig) async {
    await _preferencesDataSource.setThemeConfig(themeConfig.toString());
    notifyListeners();
  }
  
  @override
  Future<Result<void>> setDynamicColorPreference(bool useDynamicColor) async {
    await _preferencesDataSource.setDynamicColorPreference(useDynamicColor);
    notifyListeners();
  }
}