import 'package:flutter/foundation.dart';

import '../../../utils/result.dart';
import '../../model/user_data.dart';

abstract class UserDataRepository extends ChangeNotifier {
  
  Future<Result<UserData>> get userData;

  Future<Result<void>> setThemeConfig(ThemeConfig themeConfig);

  Future<Result<void>> setDynamicColorPreference(bool useDynamicColor);
  
}