import 'package:flutter/services.dart';

/// 屏幕亮度控制：经平台通道写当前 Activity 的窗口亮度。
///
/// 只有 Android 实现了原生侧（`PiliPlus` 通道的 `setBrightness` /
/// `getBrightness`）。其他平台通道未实现，调用静默失败——亮度手势在这些
/// 平台上不生效，但不影响播放与其余手势。
class const BrightnessService() {
  final MethodChannel _channel = const MethodChannel('PiliPlus');

  /// 设置窗口亮度，取值 0 到 1；传 null 恢复跟随系统。
  Future<void> setBrightness(double? brightness) async {
    try {
      await _channel.invokeMethod<bool>('setBrightness', <String, Object?>{
        'brightness': brightness,
      });
    } on PlatformException {
      // 非 Android 平台未实现：亮度手势降级为无效。
    } on MissingPluginException {
      // 同上。
    }
  }

  /// 当前窗口亮度，0 到 1；-1 表示跟随系统，null 表示读取失败。
  Future<double?> getBrightness() async {
    try {
      return await _channel.invokeMethod<double>('getBrightness');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
