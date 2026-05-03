import 'dart:async';

//import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/model/user_data.dart';
import '../utils/result.dart';

class PreferencesKey<T> {
  final String name;
  final T defaultValue;

  const PreferencesKey._(this.name, this.defaultValue);

  static const serviceSource = PreferencesKey<String>._(
    'SERVICE_SOURCE',
    'BILIBILI',
  );
  static const themeConfig = PreferencesKey<String>._(
    'THEME_CONFIG',
    'FOLLOW_SYSTEM',
  );
  static const useDynamicColor = PreferencesKey<bool>._(
    'USE_DYNAMIC_COLOR',
    true,
  );
}

class PreferencesDataSource {
  PreferencesDataSource({required SharedPreferencesAsync sharedPreferences})
    : _pref = sharedPreferences {
    _controller = .broadcast(onListen: _readAndEmitData);
  }

  final SharedPreferencesAsync _pref;
  late final StreamController<UserData> _controller;
  //final _log = Logger('PreferencesDataSource');

  Stream<UserData> get data => _controller.stream;

  Future<Result<T>> get<T>(PreferencesKey<T> key) async {
    try {
      if (T == String) {
        return .ok(await _pref.getString(key.name) ?? key.defaultValue);
      } else if (T == bool) {
        return .ok(await _pref.getBool(key.name) ?? key.defaultValue);
      } else if (T == int) {
        return .ok(await _pref.getInt(key.name) ?? key.defaultValue);
      } else if (T == double) {
        return .ok(await _pref.getDouble(key.name) ?? key.defaultValue);
      } else if (T == List<String>) {
        return .ok(await _pref.getStringList(key.name) ?? key.defaultValue);
      }
      return .error(Exception('Unsupported type for SharedPreferences: $T'));
    } on Exception catch (e) {
      return .error(e);
    }
  }

  Future<Result<T>> set<T>(PreferencesKey<T> key, T value) async {
    try {
      switch (value) {
        case String _:
        default:
      }
      if (value is String) {
        await _pref.setString(key.name, value);
      } else if (value is bool) {
        await _pref.setBool(key.name, value);
      } else if (value is int) {
        await _pref.setInt(key.name, value);
      } else if (value is double) {
        await _pref.setDouble(key.name, value);
      } else if (value is List<String>) {
        await _pref.setStringList(key.name, value);
      } else {
        return .error(
          Exception(
            'Unsupported type for SharedPreferences: ${value.runtimeType}',
          ),
        );
      }
      return .ok(value);
    } on Exception catch (e) {
      return .error(e);
    }
  }

  Future<void> _readAndEmitData() async {
    final data = UserData.fromJson(await _pref.getAll());
    if (!_controller.isClosed) {
      _controller.add(data);
    }
  }

  void dispose() {
    _controller.close();
  }
}

