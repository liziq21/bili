import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

/// 平台与网络环境工具类
///
/// 提供跨平台设备类型判断（桌面端/移动端/Web）以及网络连接状态检测。
abstract final class PlatformInfo {
  static const _desktopPlatforms = [
    TargetPlatform.macOS,
    TargetPlatform.windows,
    TargetPlatform.linux,
  ];
  static const _mobilePlatforms = [TargetPlatform.android, TargetPlatform.iOS];

  /// 是否为桌面端原生平台 (macOS, Windows, Linux)
  static bool get isDesktop =>
      _desktopPlatforms.contains(defaultTargetPlatform) && !kIsWeb;

  /// 是否为桌面端平台或 Web 平台
  static bool get isDesktopOrWeb => isDesktop || kIsWeb;

  /// 是否为移动端原生平台 (Android, iOS)
  static bool get isMobile =>
      _mobilePlatforms.contains(defaultTargetPlatform) && !kIsWeb;

  /// 获取当前首个视图的设备像素比率 (Device Pixel Ratio)
  static double get pixelRatio =>
      WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;

  /// 是否为 Windows 操作系统
  static bool get isWindows => defaultTargetPlatform == TargetPlatform.windows;

  /// 是否为 Linux 操作系统
  static bool get isLinux => defaultTargetPlatform == TargetPlatform.linux;

  /// 是否为 macOS 操作系统
  static bool get isMacOS => defaultTargetPlatform == TargetPlatform.macOS;

  /// 是否为 Android 操作系统
  static bool get isAndroid => defaultTargetPlatform == TargetPlatform.android;

  /// 是否为 iOS 操作系统
  static bool get isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  /// 异步检测当前设备是否已联网
  static Future<bool> get isConnected async =>
      await InternetConnectionChecker.instance.hasConnection;

  /// 异步检测当前设备是否断网
  static Future<bool> get isDisconnected async => (await isConnected) == false;
}
