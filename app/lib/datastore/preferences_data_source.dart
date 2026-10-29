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

  Future<Result<T, Exception>> get<T>(PreferencesKey<T> key) async {
    try {
      return .success(await key._getData(_pref));
    } on Object catch (error, stackTrace) {
      return .error(_asException(error, stackTrace));
    }
  }

  Future<Result<void, Exception>> set<T>(
    PreferencesKey<T> prefKey,
    T? value,
  ) async {
    try {
      await prefKey._setData(_pref, value);
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
      return .success(null);
    } on Object catch (error, stackTrace) {
      return .error(_asException(error, stackTrace));
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
    UserData? data;
    Object? error;
    try {
      data = UserData.fromJson(await _pref.getAll());
    } on Object catch (e) {
      error = e;
    }
    if (error != null) {
      _controller?.addError(error);
      return;
    }
    _controller?.add(data!);
  }
}

Exception _asException(Object error, StackTrace stackTrace) =>
    error is Exception ? error : Exception('$error\n$stackTrace');

class const PreferencesKey<T>._(final String name, final T defaultValue) {
  /// 无默认服务名：未选择过时为 null，由 app 层按当前服务源清单解析。
  static const sourceId = PreferencesKey<String?>._('SOURCE_ID', null);
  static const themeConfig = PreferencesKey<String>._(
    'THEME_CONFIG',
    'FOLLOW_SYSTEM',
  );

  /// JSON-encoded home-feed configuration. An empty object is deliberately
  /// decoded by [HomeConfig] as the default configuration.
  static const homeConfig = PreferencesKey<String>._('HOME_CONFIG', '{}');

  static const useDynamicColor = PreferencesKey<bool>._(
    'USE_DYNAMIC_COLOR',
    true,
  );

  /// 播放器默认倍速：用户在倍速弹窗里选过就记住，下次进入播放器自动套用。
  static const playbackRate = PreferencesKey<double>._('PLAYBACK_RATE', 1.0);

  /// Whether new video views are added to the local watch history.
  static const watchHistoryEnabled = PreferencesKey<bool>._(
    'WATCH_HISTORY_ENABLED',
    true,
  );

  /// Whether saved video progress is restored when playback starts.
  static const resumePlaybackEnabled = PreferencesKey<bool>._(
    'RESUME_PLAYBACK_ENABLED',
    true,
  );

  /// 默认画质高度：用户在画质弹窗里选过就记住，下次进入播放器就近套用。
  ///
  /// null 表示未选过，由源取默认档。
  static const preferredQualityHeight = PreferencesKey<int?>._(
    'PREFERRED_QUALITY_HEIGHT',
    null,
  );

  static const danmakuEnabled = PreferencesKey<bool>._('DANMAKU_ENABLED', true);
  static const danmakuRegularDuration = PreferencesKey<double>._(
    'DANMAKU_REGULAR_DURATION',
    8,
  );
  static const danmakuTopBottomDuration = PreferencesKey<double>._(
    'DANMAKU_TOP_BOTTOM_DURATION',
    6,
  );
  static const danmakuOpacity = PreferencesKey<double>._('DANMAKU_OPACITY', .9);
  static const danmakuFontSize = PreferencesKey<double>._(
    'DANMAKU_FONT_SIZE',
    18,
  );
  static const danmakuOutlineRadius = PreferencesKey<double>._(
    'DANMAKU_OUTLINE_RADIUS',
    2,
  );
  static const danmakuTopMaxRows = PreferencesKey<int>._(
    'DANMAKU_TOP_MAX_ROWS',
    2,
  );
  static const danmakuBottomMaxRows = PreferencesKey<int>._(
    'DANMAKU_BOTTOM_MAX_ROWS',
    2,
  );

  /// 默认画质的源侧清晰度 id：精确记住「选的是哪一档」，不靠高度近似。
  ///
  /// 与 [preferredQualityHeight] 同时写入：id 用于精确匹配，高度是源不认得
  /// 该 id 时的回退。均为 null 表示未选过，由源取默认档。
  static const preferredQualityStreamId = PreferencesKey<int?>._(
    'PREFERRED_QUALITY_STREAM_ID',
    null,
  );

  /// 睡眠定时器默认档位（分钟）。0 表示进入播放器不自动开始计时。
  static const sleepTimerDefaultMinutes = PreferencesKey<int>._(
    'SLEEP_TIMER_DEFAULT_MINUTES',
    0,
  );

  /// 播放器手势开关：水平滑动快进。默认开启，新增开关不改变既有操作习惯。
  static const gestureSeekEnabled = PreferencesKey<bool>._(
    'GESTURE_SEEK_ENABLED',
    true,
  );

  /// 播放器手势开关：右侧垂直滑动调音量。
  static const gestureVolumeEnabled = PreferencesKey<bool>._(
    'GESTURE_VOLUME_ENABLED',
    true,
  );

  /// 播放器手势开关：左侧垂直滑动调屏幕亮度。
  static const gestureBrightnessEnabled = PreferencesKey<bool>._(
    'GESTURE_BRIGHTNESS_ENABLED',
    true,
  );

  /// 播放器手势开关：长按临时加速。
  static const gestureBoostEnabled = PreferencesKey<bool>._(
    'GESTURE_BOOST_ENABLED',
    true,
  );

  /// 是否把播放进度写入本地观看历史。关掉只停止新增/更新，不删除已落库的行。
  static const historyRecordingEnabled = PreferencesKey<bool>._(
    'HISTORY_RECORDING_ENABLED',
    true,
  );

  // Dart 3.13 type patterns (`switch (T)`) only match non-nullable types:
  // Dart 3.13 type patterns (`switch (T)`) only match non-nullable types:
  // `const (String?)` is a compile error, and `T.toString()` for nullable
  // types relies on `Type.toString()` being stable in release builds, which
  // the spec does not guarantee. `_typeOf<T>()` instead captures the actual
  // `Type` value for each supported argument once; the dispatch below compares
  // those values directly, so no printed type name is involved.
  static Type _typeOf<T>() => T;

  Future<void> _setData(SharedPreferencesAsync pref, Object? value) async {
    if (value == null) {
      await pref.remove(name);
      return;
    }

    final runtimeType = _typeOf<T>();
    if ((runtimeType == _typeOf<String>() ||
            runtimeType == _typeOf<String?>()) &&
        value is String) {
      await pref.setString(name, value);
      return;
    }
    if (runtimeType == _typeOf<bool>() && value is bool) {
      await pref.setBool(name, value);
      return;
    }
    if ((runtimeType == _typeOf<int>() || runtimeType == _typeOf<int?>()) &&
        value is int) {
      await pref.setInt(name, value);
      return;
    }
    if (runtimeType == _typeOf<double>() && value is double) {
      await pref.setDouble(name, value);
      return;
    }
    if (runtimeType == _typeOf<List<String>>() && value is List<String>) {
      await pref.setStringList(name, value);
      return;
    }

    throw UnsupportedError(
      'Value for $name must match PreferencesKey<$T>, '
      'got ${value.runtimeType}',
    );
  }

  Future<T> _getData(SharedPreferencesAsync pref) async {
    final runtimeType = _typeOf<T>();
    final Future<Object?> data = switch (runtimeType) {
      _ when runtimeType == _typeOf<String>() => pref.getString(name),
      _ when runtimeType == _typeOf<String?>() => pref.getString(name),
      _ when runtimeType == _typeOf<bool>() => pref.getBool(name),
      _ when runtimeType == _typeOf<int>() => pref.getInt(name),
      _ when runtimeType == _typeOf<int?>() => pref.getInt(name),
      _ when runtimeType == _typeOf<double>() => pref.getDouble(name),
      _ when runtimeType == _typeOf<List<String>>() => pref.getStringList(name),
      _ => throw UnsupportedError('Unsupported type: $T'),
    };

    return (await data as T?) ?? defaultValue;
  }
}
