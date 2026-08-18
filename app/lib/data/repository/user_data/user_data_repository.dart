import 'package:model/model.dart';

abstract class UserDataRepository {
  Stream<UserData> get data;

  Future<Result<void>> setServiceSource(ServiceSource serviceSource);

  Future<Result<void>> setThemeConfig(ThemeConfig themeConfig);

  Future<Result<void>> setDynamicColorPreference(bool useDynamicColor);
}

