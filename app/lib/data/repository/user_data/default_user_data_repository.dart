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
  Future<Result<void>> setSourceId(String sourceId) =>
      _prefDataSource.set(PreferencesKey.sourceId, sourceId);

  @override
  Future<Result<void>> setDynamicColorPreference(bool useDynamicColor) =>
      _prefDataSource.set(PreferencesKey.useDynamicColor, useDynamicColor);

  @override
  Future<Result<void>> setThemeConfig(ThemeConfig themeConfig) =>
      _prefDataSource.set(PreferencesKey.themeConfig, themeConfig.toJson());
}
