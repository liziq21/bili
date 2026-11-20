import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 平台通知的薄封装。
///
/// 只做三件事：注册点击回调、报告「应用是否由点击本通知拉起」、显示通知。
/// 阈值判断、去重与计数基线都不在这里，因此这一层可以被测试替身整体替换，
/// 不需要真的拉起平台通道。
abstract interface class NotificationPresenter() {
  /// 当前平台能否投递通知。
  bool get isSupported;

  /// 创建通知通道并注册点击回调。
  ///
  /// [onTap] 收到被点击通知的 payload；payload 为空表示通知没有携带载荷。
  Future<void> initialize({required void Function(String? payload) onTap});

  /// 应用是否由点击通知拉起，以及该通知的 payload。
  ///
  /// 只在冷启动时有意义：进程已经在跑时点击走 [initialize] 注册的回调。
  Future<({bool launched, String? payload})> launchDetails();

  /// 申请通知权限；没有权限模型的平台返回 false。
  Future<bool> requestPermission();

  Future<void> show({
    required String title,
    required String body,
    required String payload,
  });
}

/// Android 实现，基于 `flutter_local_notifications`。
///
/// 每个方法都可能因为缺少平台通道（headless 测试、未注册插件）而失败，
/// 调用方需要把失败当成「暂时不能通知」而不是崩溃。
final class AndroidNotificationPresenter() implements NotificationPresenter {
  static const channelId = 'feed_updates';
  static const _channelName = 'Feed updates';
  static const _channelDescription = 'Notifies about new items in your feed';

  final _plugin = FlutterLocalNotificationsPlugin();

  @override
  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> initialize({
    required void Function(String? payload) onTap,
  }) async {
    if (!isSupported) return;
    final android = _android;
    if (android == null) return;

    // 建通道不会弹权限框：权限由用户从设置页显式开启时再申请。
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
      ),
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) => onTap(response.payload),
    );
  }

  @override
  Future<({bool launched, String? payload})> launchDetails() async {
    if (!isSupported) return (launched: false, payload: null);
    final details = await _android?.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) {
      return (launched: false, payload: null);
    }
    return (launched: true, payload: details.notificationResponse?.payload);
  }

  @override
  Future<bool> requestPermission() async {
    // 桌面与 web 没有可申请的通知权限模型。
    if (!isSupported) return false;
    final android = _android;
    // headless 运行（widget 测试、无 Android 宿主）没有平台通道，这不是错误：
    // 只是没有人可以问。
    if (android == null) return false;
    final granted = await android.requestNotificationsPermission();
    return granted ?? true;
  }

  @override
  Future<void> show({
    required String title,
    required String body,
    required String payload,
  }) async {
    await _plugin.show(
      id: 0,
      title: title,
      body: body,
      payload: payload,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
