import 'package:meta/meta.dart';
import 'package:model/model.dart';

import '../../datastore/preferences_data_source.dart';

/// 睡眠定时器可选的档位（分钟）。
///
/// 单一来源：设置页写下的默认值与播放器弹窗列出的档位必须同源，否则会出现
/// 「默认 90 分钟」而播放器里没有任何一项能对上的状态。
const List<int> kSleepTimerMinutes = [15, 30, 45, 60];

/// 播放器可记忆的倍速档位。
const List<double> kPlaybackRates = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

/// 设置页可表达的通用画质高度。
///
/// 设置页不知道当前服务实际提供哪些档位，因此只写高度偏好；播放器进入
/// 视频后由服务源就近解析。`null` 表示交给服务源自动选择。
const List<int?> kPreferredQualityHeights = [null, 2160, 1080, 720, 480];

const Object _unset = Object();

/// 将倍速显示为紧凑标签：1.0 → "1x"，1.5 → "1.5x"。
String playbackRateLabel(double rate) {
  var text = rate.toStringAsFixed(2);
  if (text.contains('.')) {
    text = text.replaceFirst(RegExp(r'\.?0+$'), '');
  }
  return '${text}x';
}

/// 播放器分组里的标量配置。
///
/// 默认倍速与默认画质的键已由播放器进入时消费
/// （`feature/video/common_widgets/video_player.dart`），这里不新增第二条读取
/// 路径，只给这些键一个统一的读写入口，并补上只有设置页才有的睡眠定时默认档。
@immutable
final class const PlayerSettings({
  /// 进入播放器时套用的倍速。
  final double playbackRate = 1.0,

  /// 进入播放器时优先请求的画面高度。
  final int? preferredQualityHeight,

  /// 进入播放器时优先请求的源侧画质 id。
  ///
  /// 设置页只编辑高度，因此从设置页选择任意高度时会清掉这个精确 id，
  /// 避免旧服务源的 id 覆盖用户刚选的通用高度。
  final int? preferredQualityStreamId,

  /// 睡眠定时器的默认档位（分钟）。0 表示进入播放器不自动开始计时。
  final int sleepTimerDefaultMinutes = 0,
}) {
  PlayerSettings copyWith({
    double? playbackRate,
    Object? preferredQualityHeight = _unset,
    Object? preferredQualityStreamId = _unset,
    int? sleepTimerDefaultMinutes,
  }) => PlayerSettings(
    playbackRate: playbackRate ?? this.playbackRate,
    preferredQualityHeight: identical(preferredQualityHeight, _unset)
        ? this.preferredQualityHeight
        : preferredQualityHeight as int?,
    preferredQualityStreamId: identical(preferredQualityStreamId, _unset)
        ? this.preferredQualityStreamId
        : preferredQualityStreamId as int?,
    sleepTimerDefaultMinutes:
        sleepTimerDefaultMinutes ?? this.sleepTimerDefaultMinutes,
  );

  static Future<PlayerSettings> load(PreferencesDataSource preferences) async =>
      PlayerSettings(
        playbackRate: await readSetting(
          preferences,
          PreferencesKey.playbackRate,
          1.0,
        ),
        preferredQualityHeight: await readSetting<int?>(
          preferences,
          PreferencesKey.preferredQualityHeight,
          null,
        ),
        preferredQualityStreamId: await readSetting<int?>(
          preferences,
          PreferencesKey.preferredQualityStreamId,
          null,
        ),
        sleepTimerDefaultMinutes: await readSetting(
          preferences,
          PreferencesKey.sleepTimerDefaultMinutes,
          0,
        ),
      );

  Future<void> save(PreferencesDataSource preferences) => Future.wait([
    writeSetting(preferences, PreferencesKey.playbackRate, playbackRate),
    writeSetting<int?>(
      preferences,
      PreferencesKey.preferredQualityHeight,
      preferredQualityHeight,
    ),
    writeSetting<int?>(
      preferences,
      PreferencesKey.preferredQualityStreamId,
      preferredQualityStreamId,
    ),
    writeSetting(
      preferences,
      PreferencesKey.sleepTimerDefaultMinutes,
      sleepTimerDefaultMinutes,
    ),
  ]);
}

/// 手势分组里的开关，四类手势各自独立。
///
/// 默认全开：新增开关不应改变已有用户的操作习惯，关掉才是明确的用户选择。
@immutable
final class const GestureSettings({
  final bool seekEnabled = true,
  final bool volumeEnabled = true,
  final bool brightnessEnabled = true,
  final bool boostEnabled = true,
}) {
  GestureSettings copyWith({
    bool? seekEnabled,
    bool? volumeEnabled,
    bool? brightnessEnabled,
    bool? boostEnabled,
  }) => GestureSettings(
    seekEnabled: seekEnabled ?? this.seekEnabled,
    volumeEnabled: volumeEnabled ?? this.volumeEnabled,
    brightnessEnabled: brightnessEnabled ?? this.brightnessEnabled,
    boostEnabled: boostEnabled ?? this.boostEnabled,
  );

  static Future<GestureSettings> load(
    PreferencesDataSource preferences,
  ) async => GestureSettings(
    seekEnabled: await readSetting(
      preferences,
      PreferencesKey.gestureSeekEnabled,
      true,
    ),
    volumeEnabled: await readSetting(
      preferences,
      PreferencesKey.gestureVolumeEnabled,
      true,
    ),
    brightnessEnabled: await readSetting(
      preferences,
      PreferencesKey.gestureBrightnessEnabled,
      true,
    ),
    boostEnabled: await readSetting(
      preferences,
      PreferencesKey.gestureBoostEnabled,
      true,
    ),
  );

  Future<void> save(PreferencesDataSource preferences) => Future.wait([
    writeSetting(preferences, PreferencesKey.gestureSeekEnabled, seekEnabled),
    writeSetting(
      preferences,
      PreferencesKey.gestureVolumeEnabled,
      volumeEnabled,
    ),
    writeSetting(
      preferences,
      PreferencesKey.gestureBrightnessEnabled,
      brightnessEnabled,
    ),
    writeSetting(preferences, PreferencesKey.gestureBoostEnabled, boostEnabled),
  ]);
}

/// 库/历史分组里的开关。
///
/// 默认全开：关掉只停止新增/更新，不删除已经落库的历史行——删除历史是另一件事，
/// 不该由一个开关顺带发生。
@immutable
final class const LibrarySettings({
  final bool historyRecordingEnabled = true,
  final bool resumePlaybackEnabled = true,
}) {
  LibrarySettings copyWith({
    bool? historyRecordingEnabled,
    bool? resumePlaybackEnabled,
  }) => LibrarySettings(
    historyRecordingEnabled:
        historyRecordingEnabled ?? this.historyRecordingEnabled,
    resumePlaybackEnabled: resumePlaybackEnabled ?? this.resumePlaybackEnabled,
  );

  static Future<LibrarySettings> load(
    PreferencesDataSource preferences,
  ) async => LibrarySettings(
    historyRecordingEnabled: await readSetting(
      preferences,
      PreferencesKey.historyRecordingEnabled,
      true,
    ),
    resumePlaybackEnabled: await readSetting(
      preferences,
      PreferencesKey.resumePlaybackEnabled,
      true,
    ),
  );

  Future<void> save(PreferencesDataSource preferences) => Future.wait([
    writeSetting(
      preferences,
      PreferencesKey.historyRecordingEnabled,
      historyRecordingEnabled,
    ),
    writeSetting(
      preferences,
      PreferencesKey.resumePlaybackEnabled,
      resumePlaybackEnabled,
    ),
  ]);
}

/// 读一个标量设置键，读取失败时退回 [fallback]。
///
/// 偏好层读取失败（平台异常）不该让整页设置不可用，因此错误一律吞成默认值。
Future<T> readSetting<T>(
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

/// 写一个标量设置键，失败时抛出。
///
/// 写失败必须让调用方知道：设置页只在读回来之后才显示新值，静默失败会表现为
/// 「开关拨了又弹回去」而没有任何线索。
Future<void> writeSetting<T>(
  PreferencesDataSource preferences,
  PreferencesKey<T> key,
  T value,
) async {
  final result = await preferences.set(key, value);
  if (result case Error(:final error)) throw error;
}
