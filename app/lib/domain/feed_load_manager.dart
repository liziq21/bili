import 'dart:async';

import 'package:logging/logging.dart';
import 'package:model/model.dart';

import '../data/repository/feed_repository.dart';
import '../datastore/preferences_data_source.dart';
import '../feature/notification/feed_update_notifier.dart';

/// 订阅 Feed 的触发式加载入口。
///
/// 触发点是应用启动与用户主动刷新，不引入定时后台任务：启动时拉一次增量，
/// 之后每次刷新再拉。加载本身只追加新条目（[FeedRepository] 负责判定），
/// 通知是否发出交给 [FeedUpdateNotifier]，本类不碰平台细节。
class FeedLoadManager({
  required final FeedRepository _repository,
  required final FeedUpdateNotifier _notifier,
  required final PreferencesDataSource _preferences,
}) {
  final _log = Logger('FeedLoadManager');

  /// 进行中的加载。重复触发复用同一个 Future，避免并发重复拉取。
  Future<FeedLoadResult>? _inFlight;

  /// 加载 [sourceId] 下的订阅增量，必要时发更新通知。
  ///
  /// 通知与通知写入失败都不影响返回的加载结果：用户至少要看到新条目。
  Future<FeedLoadResult> load({required String sourceId}) {
    final existing = _inFlight;
    if (existing != null) return existing;

    final future = _load(sourceId);
    _inFlight = future;
    return future.whenComplete(() => _inFlight = null);
  }

  Future<FeedLoadResult> _load(String sourceId) async {
    final result = await _repository.loadIncremental(sourceId: sourceId);
    if (result.newEntryCount > 0) {
      _log.info('Loaded ${result.newEntryCount} new feed entries');
    }
    await _notifyIfNeeded(result.unreadCount);
    return result;
  }

  Future<void> _notifyIfNeeded(int unreadCount) async {
    final threshold = await _readInt(
      PreferencesKey.feedUpdateNotificationThreshold,
    );
    final lastCount = await _readInt(
      PreferencesKey.feedUpdateNotificationLastCount,
    );
    final notified = await _notifier.notifyIfThresholdReached(
      currentCount: unreadCount,
      threshold: threshold,
      lastNotifiedCount: lastCount,
    );
    final baseline = switch (notified) {
      Success(:final success) => success,
      Error(:final error) => () {
        _log.warning('Feed update notification failed', error);
        return lastCount;
      }(),
    };
    // 未读数回落到已通知基线以下（用户读过或退订）时同步下调基线，
    // 否则之后的增长永远够不到阈值，再也不会提醒。
    if (unreadCount < baseline) {
      await _preferences.set(
        PreferencesKey.feedUpdateNotificationLastCount,
        unreadCount,
      );
    }
  }

  Future<int> _readInt(PreferencesKey<int> key) async {
    final result = await _preferences.get(key);
    return switch (result) {
      Success(:final success) => success,
      Error() => key.defaultValue,
    };
  }
}
