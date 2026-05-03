// ignore_for_file: void_checks

import 'dart:async';

import '../../../datastore/preferences_data_source.dart';
import '../../../utils/result.dart';
import '../../model/user_data.dart';
import 'user_data_repository.dart';

class DefaultUserDataRepository implements UserDataRepository {
  const DefaultUserDataRepository({
    required PreferencesDataSource preferencesDataSource,
  }) : _prefDataSource = preferencesDataSource;

  final PreferencesDataSource _prefDataSource;

  @override
  Stream<UserData> get data => _prefDataSource.data;

  @override
  Future<Result<void>> setServiceSource(ServiceSource serviceSource) =>
      _prefDataSource.set(PreferencesKey.serviceSource, serviceSource);

  @override
  Future<Result<void>> setDynamicColorPreference(bool useDynamicColor) =>
      _prefDataSource.set(PreferencesKey.useDynamicColor, useDynamicColor);

  @override
  Future<Result<void>> setThemeConfig(ThemeConfig themeConfig) =>
      _prefDataSource.set(PreferencesKey.themeConfig, themeConfig.toJson());
}

