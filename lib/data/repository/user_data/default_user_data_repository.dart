import '../../../datastore/preferences_data_source.dart';
import '../../../utils/result.dart';
import '../../model/user_data.dart';
import 'user_data_repository.dart';

class DefaultUserDataRepository implements UserDataRepository {
  DefaultUserDataRepository({
    required PreferencesDataSource preferencesDataSource,
  }) : _prefDataSource = preferencesDataSource;
  
  final PreferencesDataSource _prefDataSource;
  final _dynamicColorPreferenceController = StreamController<bool>.broadcast();
  final _themeConfigController = StreamController<ThemeConfig>.broadcast();

  @override
  Future<Result<bool>> dynamicColorPreference() {
    return _prefDataSource.get(PreferencesKey.useDynamicColor);
  }

  @override
  Future<Result<ThemeConfig>> themeConfig() {
    final result = _prefDataSource.get(PreferencesKey.themeConfig);
    return result.map(ThemeConfig.fromJson);
  }

  @override
  Future<Result<void>> setDynamicColorPreference(bool useDynamicColor) async {
    final result = await _prefDataSource.set(PreferencesKey.useDynamicColor, useDynamicColor);
    if (result.isOk) {
      _dynamicColorPreferenceController.add(result.value);
    }
    return result;
  }
  
  @override
  Future<Result<void>> setThemeConfig(ThemeConfig themeConfig) async {
    final result = await _prefDataSource.set(PreferencesKey.themeConfig, themeConfig.toJson());
    if (result.isOk) {
      _themeConfigController.add(result.value);
    }
    return result;
  }
  
  Stream<bool> observeDynamicColorPreference() => _dynamicColorPreferenceController.stream;
  Stream<bool> observeThemeConfig() => _themeConfigController.stream;
}