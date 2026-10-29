import 'package:model/model.dart';

abstract class UserDataRepository() {
  Stream<UserData> get data;

  Future<Result<void, Exception>> setSourceId(String sourceId);

  Future<Result<void, Exception>> setThemeConfig(ThemeConfig themeConfig);

  Future<Result<void, Exception>> setDynamicColorPreference(bool useDynamicColor);
}
