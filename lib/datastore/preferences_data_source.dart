import 'dart:async';

//import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/model/user_data.dart';
import '../utils/result.dart';

class PreferencesDataSource {
  PreferencesDataSource({required SharedPreferencesAsync sharedPreferences})
    : _pref = sharedPreferences {
    _controller = .broadcast(onListen: _readAndEmitData);
  }

  final SharedPreferencesAsync _pref;
  //final _log = Logger('PreferencesDataSource');
  late final StreamController<UserData> _controller;

  Stream<UserData> get data => _controller.stream;

  Future<void> dispose() => _controller.close();

  Future<Result<T>> get<T>(PreferencesKey<T> key) async {
    try {
      return .ok(await key.getData(_pref));
    } on Exception catch (e) {
      return .error(e);
    }
  }

  Future<Result<T>> set<T>(PreferencesKey<T> key, T value) async {
    try {
      await switch (value) {
        final String v => _pref.setString(key.name, v),
        final bool v => _pref.setBool(key.name, v),
        final int v => _pref.setInt(key.name, v),
        final double v => _pref.setDouble(key.name, v),
        final List<String> v => _pref.setStringList(key.name, v),
        _ => throw Exception('Unsupported type: ${value.runtimeType}'),
      };

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
}

class PreferencesKey<T> {
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

  final String name;
  final T defaultValue;
  const PreferencesKey._(this.name, this.defaultValue);

  Future<T> getData(SharedPreferencesAsync pref) async {
    final Future<Object?> data = switch (T) {
      const (String) => pref.getString(name),
      const (bool) => pref.getBool(name),
      const (int) => pref.getInt(name),
      const (double) => pref.getDouble(name),
      const (List<String>) => pref.getStringList(name),
      _ => throw UnsupportedError('不支持的类型: $T'),
    };

    return (await data as T?) ?? defaultValue;
  }
}
