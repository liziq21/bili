import '../../l10n/localization_file/app_localizations.dart';
import 'notification_locale.dart';
import 'notification_presenter.dart';

/// 睡眠定时器的系统提醒。
///
/// 与 `FeedUpdateNotifier` 分开：订阅更新有阈值、去重和点击跳转，睡眠定时器
/// 只有一句「即将停止播放」。拆开也避免定时器的一次提醒改写订阅更新的计数基线。
abstract interface class SleepTimerNotifier() {
  /// 申请通知权限。只在定时器会真正停播时调用，避免启动即弹系统框。
  Future<void> requestPermission();

  /// 倒计时进入最后一分钟时提醒一次。
  Future<void> notifyEndingSoon({int id = defaultSleepTimerNotificationId});

  /// 撤掉「即将停止播放」提醒：定时器被取消、重设或离开播放器时调用。
  Future<void> cancel({int id = defaultSleepTimerNotificationId});
}

/// 单条提醒的默认 id；每个计时会话应当用 [allocateSleepTimerNotificationId]
/// 领一个自己的 id，叠加两个播放器时取消其一不会撤掉另一个的提醒。
const defaultSleepTimerNotificationId = 1;

int _nextNotificationId = defaultSleepTimerNotificationId + 1;

int allocateSleepTimerNotificationId() => _nextNotificationId++;

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

  /// 文案与界面同语言。
  final AppLocalizations _l10n =
      localizations ?? resolveNotificationLocalizations();

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
  Future<void> notifyEndingSoon({
    int id = defaultSleepTimerNotificationId,
  }) async {
    if (!_presenter.isSupported) return;
    try {
      await _presenter.show(
        title: _l10n.sleepTimerEndingSoonTitle,
        body: _l10n.sleepTimerEndingSoonBody,
        payload: sleepTimerNotificationPayload,
        id: id,
        channelId: sleepTimerChannelId,
        channelName: _l10n.sleepTimerChannelName,
        channelDescription: _l10n.sleepTimerChannelDescription,
      );
    } on Object catch (_) {
      // 没有权限或插件未初始化时保持安静。
    }
  }

  @override
  Future<void> cancel({int id = defaultSleepTimerNotificationId}) async {
    if (!_presenter.isSupported) return;
    try {
      await _presenter.cancel(id: id);
    } on Object catch (_) {
      // 通知不存在或通道不可用时无需处理。
    }
  }
}
