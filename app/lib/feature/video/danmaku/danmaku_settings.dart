import 'package:meta/meta.dart';
import 'package:model/model.dart';

import '../../../datastore/preferences_data_source.dart';

@immutable
final class const DanmakuSettings({
  final bool enabled = true,
  final double regularDuration = 8,
  final double topBottomDuration = 6,
  final double opacity = .9,
  final double fontSize = 18,
  final double outlineRadius = 2,
  final int topMaxRows = 2,
  final int bottomMaxRows = 2,
}) {
  DanmakuSettings copyWith({
    bool? enabled,
    double? regularDuration,
    double? topBottomDuration,
    double? opacity,
    double? fontSize,
    double? outlineRadius,
    int? topMaxRows,
    int? bottomMaxRows,
  }) => DanmakuSettings(
    enabled: enabled ?? this.enabled,
    regularDuration: regularDuration ?? this.regularDuration,
    topBottomDuration: topBottomDuration ?? this.topBottomDuration,
    opacity: opacity ?? this.opacity,
    fontSize: fontSize ?? this.fontSize,
    outlineRadius: outlineRadius ?? this.outlineRadius,
    topMaxRows: topMaxRows ?? this.topMaxRows,
    bottomMaxRows: bottomMaxRows ?? this.bottomMaxRows,
  );

  static Future<DanmakuSettings> load(PreferencesDataSource preferences) async {
    return DanmakuSettings(
      enabled: await _read(preferences, PreferencesKey.danmakuEnabled, true),
      regularDuration: await _read(
        preferences,
        PreferencesKey.danmakuRegularDuration,
        8,
      ),
      topBottomDuration: await _read(
        preferences,
        PreferencesKey.danmakuTopBottomDuration,
        6,
      ),
      opacity: await _read(preferences, PreferencesKey.danmakuOpacity, .9),
      fontSize: await _read(preferences, PreferencesKey.danmakuFontSize, 18),
      outlineRadius: await _read(
        preferences,
        PreferencesKey.danmakuOutlineRadius,
        2,
      ),
      topMaxRows: await _read(preferences, PreferencesKey.danmakuTopMaxRows, 2),
      bottomMaxRows: await _read(
        preferences,
        PreferencesKey.danmakuBottomMaxRows,
        2,
      ),
    );
  }

  Future<void> save(PreferencesDataSource preferences) async {
    await Future.wait([
      _set(preferences, PreferencesKey.danmakuEnabled, enabled),
      _set(preferences, PreferencesKey.danmakuRegularDuration, regularDuration),
      _set(
        preferences,
        PreferencesKey.danmakuTopBottomDuration,
        topBottomDuration,
      ),
      _set(preferences, PreferencesKey.danmakuOpacity, opacity),
      _set(preferences, PreferencesKey.danmakuFontSize, fontSize),
      _set(preferences, PreferencesKey.danmakuOutlineRadius, outlineRadius),
      _set(preferences, PreferencesKey.danmakuTopMaxRows, topMaxRows),
      _set(preferences, PreferencesKey.danmakuBottomMaxRows, bottomMaxRows),
    ]);
  }

  static Future<T> _read<T>(
    PreferencesDataSource preferences,
    PreferencesKey<T> key,
    T fallback,
  ) async {
    final result = await preferences.get(key);
    return switch (result) {
      Ok(:final value) => value,
      Error() => fallback,
    };
  }

  static Future<void> _set<T>(
    PreferencesDataSource preferences,
    PreferencesKey<T> key,
    T value,
  ) async {
    final result = await preferences.set(key, value);
    if (result case Error(:final error)) throw error;
  }
}
