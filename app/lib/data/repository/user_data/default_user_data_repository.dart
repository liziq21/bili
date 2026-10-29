// ignore_for_file: void_checks

import 'dart:async';

import 'package:model/model.dart';

import '../../../datastore/preferences_data_source.dart';
import 'user_data_repository.dart';

class const DefaultUserDataRepository(
  final PreferencesDataSource preferencesDataSource,
) implements UserDataRepository {
  this : _prefDataSource = preferencesDataSource;

  final PreferencesDataSource _prefDataSource;

  @override
  Stream<UserData> get data => _prefDataSource.data;

  @override
  Future<Result<void, Exception>> setSourceId(String sourceId) =>
      _prefDataSource.set(PreferencesKey.sourceId, sourceId);

  @override
  Future<Result<void, Exception>> setDynamicColorPreference(
    bool useDynamicColor,
  ) => _prefDataSource.set(PreferencesKey.useDynamicColor, useDynamicColor);

  @override
  Future<Result<void, Exception>> setThemeConfig(ThemeConfig themeConfig) =>
      _prefDataSource.set(PreferencesKey.themeConfig, themeConfig.toJson());
}
