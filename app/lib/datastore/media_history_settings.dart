import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:model/model.dart';

import 'preferences_data_source.dart';

/// Controls which local video-history behaviours are enabled.
@immutable
class const MediaHistorySettings({
  final bool recordHistory = true,
  final bool resumePlayback = true,
}) with Equatable {
  /// Whether a video may read a saved position before playback starts.
  bool get shouldReadProgress => recordHistory && resumePlayback;

  /// Whether a video may create or update its local history row.
  bool get shouldWriteHistory => recordHistory;

  static Future<MediaHistorySettings> load(
    PreferencesDataSource preferences,
  ) async {
    final recordResult = await preferences.get(
      PreferencesKey.watchHistoryEnabled,
    );
    final resumeResult = await preferences.get(
      PreferencesKey.resumePlaybackEnabled,
    );

    return MediaHistorySettings(
      recordHistory: recordResult is Ok<bool> ? recordResult.value : true,
      resumePlayback: resumeResult is Ok<bool> ? resumeResult.value : true,
    );
  }

  Future<void> save(PreferencesDataSource preferences) async {
    await Future.wait([
      preferences.set(PreferencesKey.watchHistoryEnabled, recordHistory),
      preferences.set(PreferencesKey.resumePlaybackEnabled, resumePlayback),
    ]);
  }

  MediaHistorySettings copyWith({bool? recordHistory, bool? resumePlayback}) {
    return MediaHistorySettings(
      recordHistory: recordHistory ?? this.recordHistory,
      resumePlayback: resumePlayback ?? this.resumePlayback,
    );
  }

  @override
  List<Object> get props => [recordHistory, resumePlayback];
}
