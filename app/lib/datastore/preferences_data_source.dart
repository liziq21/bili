import 'dart:async';

import 'package:model/model.dart';
//import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'preferences_key_set.dart';

class PreferencesDataSource({SharedPreferencesAsync? sharedPreferences}) {
  this : _pref = sharedPreferences ?? .new();

  final SharedPreferencesAsync _pref;
  //final _log = Logger('PreferencesDataSource');
  StreamController<UserData>? _controller;

  final Map<PreferencesKey, StreamController<Object?>> _keyControllers = {};

  final Map<PreferencesKeySet, StreamController<Object?>> _keySetControllers =
      {};

  Stream<UserData> get data {
    _controller ??= .broadcast(onListen: _readAndEmitData);
    return _controller!.stream;
  }

  void dispose() {
    for (final controller in _keyControllers.values) {
      controller.close();
    }
    _keyControllers.clear();
    _controller?.close();
    _controller = null;
  }

  Future<Result<T>> get<T>(PreferencesKey<T> key) async {
    try {
      return .ok(await key._getData(_pref));
    } on Exception catch (e) {
      return .error(e);
    }
  }

  Future<Result<void>> set<T>(PreferencesKey<T> prefKey, T? value) async {
    try {
      await switch (value) {
        final String v => _pref.setString(prefKey.name, v),
        final bool v => _pref.setBool(prefKey.name, v),
        final int v => _pref.setInt(prefKey.name, v),
        final double v => _pref.setDouble(prefKey.name, v),
        final List<String> v => _pref.setStringList(prefKey.name, v),
        null => _pref.remove(prefKey.name),
        _ => throw UnsupportedError('Unsupported type: ${value.runtimeType}'),
      };
      await _readAndEmitData();
      if (_keyControllers.containsKey(prefKey)) {
        _keyControllers[prefKey]!.add(value ?? prefKey.defaultValue);
      }
      for (final MapEntry(:key, :value) in _keySetControllers.entries) {
        if (key.keys.contains(prefKey)) {
          final updatedSetData = await _getSetData(key);
          value.add(updatedSetData);
        }
      }
      return .ok(null);
    } on Exception catch (e) {
      return .error(e);
    }
  }

  Stream<R> _getOrCreateStream<K, R>({
    required Map<K, StreamController<Object?>> cacheMap,
    required K cacheKey,
    required Future<R> Function() fetchInitialData,
  }) {
    if (cacheMap.containsKey(cacheKey)) {
      return cacheMap[cacheKey]!.stream as Stream<R>;
    }

    // ignore: close_sinks
    final controller = StreamController<R>.broadcast(
      onListen: () async {
        final initialData = await fetchInitialData();
        if (cacheMap.containsKey(cacheKey) && !cacheMap[cacheKey]!.isClosed) {
          cacheMap[cacheKey]!.add(initialData);
        }
      },
      onCancel: () => cacheMap.remove(cacheKey),
    );

    cacheMap[cacheKey] = controller;
    return controller.stream;
  }

  Stream<T> streamOf<T>(PreferencesKey<T> key) {
    return _getOrCreateStream<PreferencesKey, T>(
      cacheMap: _keyControllers,
      cacheKey: key,
      fetchInitialData: () => key._getData(_pref),
    );
  }

  Stream<T> streamOfSet<T>(PreferencesKeySet<T> keySet) {
    return _getOrCreateStream<PreferencesKeySet, T>(
      cacheMap: _keySetControllers,
      cacheKey: keySet,
      fetchInitialData: () => _getSetData(keySet),
    );
  }

  Future<T> _getSetData<T>(PreferencesKeySet<T> keySet) async {
    final keys = await _pref.getAll(
      allowList: keySet.keys.map((key) => key.name).toSet(),
    );
    return keySet.fromJson(keys);
  }

  Future<void> _readAndEmitData() async {
    final data = UserData.fromJson(await _pref.getAll());
    _controller?.add(data);
  }
}

class const PreferencesKey<T>._(final String name, final T defaultValue) {
  /// 无默认服务名：未选择过时为 null，由 app 层按当前服务源清单解析。
  static const sourceId = PreferencesKey<String?>._('SOURCE_ID', null);
  static const themeConfig = PreferencesKey<String>._(
    'THEME_CONFIG',
    'FOLLOW_SYSTEM',
  );

  static const useDynamicColor = PreferencesKey<bool>._(
    'USE_DYNAMIC_COLOR',
    true,
  );

  // Dart 3.13 type patterns (`switch (T)`) only match non-nullable types:
  // `const (String?)` is a compile error, and `T.toString()` for nullable
  // types relies on `Type.toString()` being stable in release builds, which
  // the spec does not guarantee. `_typeOf<T>()` instead captures the actual
  // `Type` value for each supported argument once; the dispatch below uses
  // `identical` (value identity) against those captured objects, so no
  // printed type name is involved.
  static Type _typeOf<T>() => T;

  Future<T> _getData(SharedPreferencesAsync pref) async {
    final runtimeType = _typeOf<T>();
    final Future<Object?> data = switch (runtimeType) {
      _ when identical(runtimeType, _typeOf<String>()) => pref.getString(name),
      _ when identical(runtimeType, _typeOf<String?>()) => pref.getString(name),
      _ when identical(runtimeType, _typeOf<bool>()) => pref.getBool(name),
      _ when identical(runtimeType, _typeOf<int>()) => pref.getInt(name),
      _ when identical(runtimeType, _typeOf<double>()) => pref.getDouble(name),
      _ when identical(runtimeType, _typeOf<List<String>>()) => pref.getStringList(name),
      _ => throw UnsupportedError('Unsupported type: $T'),
    };

    return (await data as T?) ?? defaultValue;
  }
}
