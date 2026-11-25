import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:model/model.dart';

import '../../../datastore/preferences_data_source.dart';

@immutable
final class const DanmakuSettings({
  final bool enabled = true,
  final double regularDuration = 8,
  final double opacity = .9,
  final double fontSize = 18,
  final double outlineRadius = 2,
}) with Equatable {
  @override
  List<Object?> get props => [
    enabled,
    regularDuration,
    opacity,
    fontSize,
    outlineRadius,
  ];

  DanmakuSettings copyWith({
    bool? enabled,
    double? regularDuration,
    double? opacity,
    double? fontSize,
    double? outlineRadius,
  }) => DanmakuSettings(
    enabled: enabled ?? this.enabled,
    regularDuration: regularDuration ?? this.regularDuration,
    opacity: opacity ?? this.opacity,
    fontSize: fontSize ?? this.fontSize,
    outlineRadius: outlineRadius ?? this.outlineRadius,
  );

  static Future<DanmakuSettings> load(
    PreferencesDataSource preferences, {
    DanmakuSettings fallback = const DanmakuSettings(),
  }) async {
    return DanmakuSettings(
      enabled: await _read(
        preferences,
        PreferencesKey.danmakuEnabled,
        fallback.enabled,
      ),
      regularDuration: await _read(
        preferences,
        PreferencesKey.danmakuRegularDuration,
        fallback.regularDuration,
      ),
      opacity: await _read(
        preferences,
        PreferencesKey.danmakuOpacity,
        fallback.opacity,
      ),
      fontSize: await _read(
        preferences,
        PreferencesKey.danmakuFontSize,
        fallback.fontSize,
      ),
      outlineRadius: await _read(
        preferences,
        PreferencesKey.danmakuOutlineRadius,
        fallback.outlineRadius,
      ),
    );
  }

  Future<void> save(PreferencesDataSource preferences) async {
    await Future.wait([
      _set(preferences, PreferencesKey.danmakuEnabled, enabled),
      _set(preferences, PreferencesKey.danmakuRegularDuration, regularDuration),
      _set(preferences, PreferencesKey.danmakuOpacity, opacity),
      _set(preferences, PreferencesKey.danmakuFontSize, fontSize),
      _set(preferences, PreferencesKey.danmakuOutlineRadius, outlineRadius),
    ]);
  }

  static Future<T> _read<T>(
    PreferencesDataSource preferences,
    PreferencesKey<T> key,
    T fallback,
  ) async {
    final result = await preferences.get(key);
    return switch (result) {
      Success(:final success) => success,
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
