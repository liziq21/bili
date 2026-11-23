import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:model/model.dart';

import '../../datastore/preferences_data_source.dart';
import '../../l10n/localization_file/app_localizations.dart';
import 'feed_update_notifier.dart';
import 'notification_locale.dart';
import 'notification_presenter.dart';

/// Android implementation of [FeedUpdateNotifier] backed by
/// [NotificationPresenter].
///
/// Every method is best effort: notification failures are reported as
/// [Error] results and never thrown, so a missing permission or a broken
/// platform channel cannot break the caller that polls the feed.
///
/// Threshold arithmetic lives here; showing, cancelling and receiving taps is
/// delegated to the presenter so the decision logic stays testable without a
/// platform channel.
final class LocalFeedUpdateNotifier(
  final PreferencesDataSource _preferences, {
  NotificationPresenter? presenter,
  AppLocalizations? localizations,
}) implements FeedUpdateNotifier {
  final NotificationPresenter _presenter =
      presenter ?? AndroidNotificationPresenter();

  /// 通知文案与界面同语言；测试可注入固定文案。
  final AppLocalizations _l10n =
      localizations ?? resolveNotificationLocalizations();

  // broadcast: 应用生命周期内可能有多个监听者（shell 重建），而 `initialize`
  // 之前通常还没有人订阅。
  //
  // 冷启动的点击在 [initialize] 里就落地了，那时订阅者往往还没挂上；记成
  // 待投递标志，首个订阅者到来时补发一次，否则由通知拉起的启动会静默丢掉
  // 那次跳转。用 `onListen` 而不是在 getter 里补发：只读取流不订阅不该消耗它。
  late final _opened = StreamController<void>.broadcast(
    onListen: _flushPending,
  );

  bool _pendingColdStart = false;
  bool _initialized = false;

  void _flushPending() {
    if (!_pendingColdStart || _opened.isClosed) return;
    _pendingColdStart = false;
    // 首次订阅时 onListen 早于订阅真正生效，同步 add 会丢；推迟一个微任务。
    scheduleMicrotask(() {
      if (!_opened.isClosed) _opened.add(null);
    });
  }

  @override
  bool get isSupported => _presenter.isSupported;

  @override
  Stream<void> get feedOpened => _opened.stream;

  @override
  Future<Result<void, Exception>> initialize() async {
    if (!isSupported || _initialized) {
      return const Result.success(null);
    }

    try {
      // 通道创建不弹框；权限由 [requestPermission] 在用户显式开启时申请。
      //
      // 同一个插件也投递睡眠定时器提醒，只有订阅更新的载荷才该跳去动态。
      await _presenter.initialize(
        onTap: (payload) {
          if (payload == feedNotificationPayload) _emitOpened();
        },
      );
      _initialized = true;

      final launch = await _presenter.launchDetails();
      if (launch.launched && launch.payload == feedNotificationPayload) {
        _emitOpened();
      }

      return const Result.success(null);
    } on Object catch (error, stackTrace) {
      return Result.error(
        Exception('Failed to initialize notifications: $error\n$stackTrace'),
      );
    }
  }

  /// 点击既可能发生在应用已运行时，也可能就是拉起应用的那一下。
  ///
  /// 没有订阅者时记为待投递，而不是直接丢弃。通知本身由 Android 的
  /// `autoCancel` 在点击时移除，这里不需要再 cancel 一次。
  void _emitOpened() {
    final controller = _opened;
    if (controller.isClosed) return;
    if (!controller.hasListener) {
      _pendingColdStart = true;
      return;
    }
    controller.add(null);
  }

  @override
  Future<Result<bool, Exception>> requestPermission() async {
    // Desktop and web builds have no notification permission model to ask for.
    if (!isSupported) return const Result.success(false);

    try {
      final granted = await _presenter.requestPermission();
      return Result.success(granted);
    } on Object catch (error, stackTrace) {
      // A missing or broken channel is indistinguishable from a denial here;
      // callers treat both as "cannot notify right now".
      debugPrint('Notification permission unavailable: $error');
      debugPrintStack(stackTrace: stackTrace);
      return const Result.success(false);
    }
  }

  @override
  Future<Result<int, Exception>> notifyIfThresholdReached({
    required int currentCount,
    required int threshold,
    required int lastNotifiedCount,
  }) async {
    // A threshold of 0 (or less) means the user turned the feature off.
    if (!isSupported || threshold <= 0) {
      return Result.success(lastNotifiedCount);
    }

    final newItems = currentCount - lastNotifiedCount;
    // The count can go backwards when the feed shrinks (unsubscribing, a
    // filtered source). Treat that as "nothing new" instead of notifying.
    if (newItems < threshold) {
      return Result.success(lastNotifiedCount);
    }

    final initResult = await initialize();
    if (initResult case Error()) {
      return Result.success(lastNotifiedCount);
    }

    try {
      await _presenter.show(
        title: _l10n.feedUpdateNotificationTitle,
        body: _l10n.feedUpdateNotificationBody(newItems),
        // Payload 标记目的地；点击回调按它过滤，睡眠提醒不会误跳动态。
        payload: feedNotificationPayload,
      );
      await _preferences.set(
        PreferencesKey.feedUpdateNotificationLastCount,
        currentCount,
      );
      return Result.success(currentCount);
    } on Object catch (error, stackTrace) {
      return Result.error(
        Exception('Failed to show notification: $error\n$stackTrace'),
      );
    }
  }

  @override
  Future<void> dispose() async {
    _initialized = false;
    await _opened.close();
  }
}
