import 'package:material_ui/material_ui.dart';

/// 服务身份色 —— R1 允许出现颜色字面量的两个文件之二。
///
/// 这些不是 UI 角色色，是**服务身份**：B 站蓝/粉/红、YouTube 红。它们的语义
/// 是「这是哪个平台」，不是「这是正文还是背景」，因此不参与暗色反转，也不
/// 参与 `ColorScheme` 构造——放进 `ColorScheme` 会让 Material 组件把它们当
/// 界面角色用（见 `app/docs/design-system.md` §7.3）。
abstract final class ServiceBrands() {
  /// B 站主蓝。
  static const Color bilibiliBlue = Color(0xFF00A1D6);

  /// B 站等级色：红（Lv6）。
  static const Color bilibiliRed = Color(0xFFEF5350);

  /// B 站等级色：粉（Lv5）。
  static const Color bilibiliPink = Color(0xFFFB7299);

  /// YouTube 品牌红。
  static const Color youtubeRed = Color(0xFFFF0000);
}
