import 'dart:ui' show Locale, PlatformDispatcher;

import '../../l10n/localization_file/app_localizations.dart';
import 'notification_presenter.dart';

/// 睡眠定时器的系统提醒。
///
/// 与 `FeedUpdateNotifier` 分开：订阅更新有阈值、去重和点击跳转，睡眠定时器
/// 只有一句「即将停止播放」。拆开也避免定时器的一次提醒改写订阅更新的计数基线。
abstract interface class SleepTimerNotifier() {
  /// 申请通知权限。只在用户主动启动定时器时调用，避免启动即弹系统框。
  Future<void> requestPermission();

  /// 倒计时进入最后一分钟时提醒一次。
  Future<void> notifyEndingSoon();
}

/// Android 实现，基于 [NotificationPresenter] 的独立通道。
///
/// 每次调用都是尽力而为：缺少权限、没有平台通道或插件尚未初始化时静默失败，
/// 不能让一次通知失败打断播放。
final class LocalSleepTimerNotifier({
  NotificationPresenter? presenter,
  AppLocalizations? localizations,
}) implements SleepTimerNotifier {
  final NotificationPresenter _presenter =
      presenter ?? AndroidNotificationPresenter();

  /// 文案与界面同语言，解析规则与 `MaterialApp.localeResolutionCallback` 一致。
  final AppLocalizations _l10n =
      localizations ??
      lookupAppLocalizations(
        switch (PlatformDispatcher.instance.locale.languageCode) {
          'zh' => const Locale('zh'),
          _ => const Locale('en'),
        },
      );

  @override
  Future<void> requestPermission() async {
    if (!_presenter.isSupported) return;
    try {
      await _presenter.requestPermission();
    } on Object catch (_) {
      // 权限请求失败不是播放错误。
    }
  }

  @override
  Future<void> notifyEndingSoon() async {
    if (!_presenter.isSupported) return;
    try {
      await _presenter.show(
        title: _l10n.sleepTimerEndingSoonTitle,
        body: _l10n.sleepTimerEndingSoonBody,
        payload: '',
        id: 1,
        channelId: sleepTimerChannelId,
        channelName: sleepTimerChannelName,
        channelDescription: sleepTimerChannelDescription,
      );
    } on Object catch (_) {
      // 没有权限或插件未初始化时保持安静。
    }
  }
}
