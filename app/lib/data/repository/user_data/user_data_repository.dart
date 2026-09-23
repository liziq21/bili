import 'package:model/model.dart';

abstract class UserDataRepository() {
  Stream<UserData> get data;

  Future<Result<void>> setSourceId(String sourceId);

  Future<Result<void>> setThemeConfig(ThemeConfig themeConfig);

  Future<Result<void>> setDynamicColorPreference(bool useDynamicColor);
}
