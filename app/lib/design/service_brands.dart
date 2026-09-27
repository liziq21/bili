import 'package:material_ui/material_ui.dart';

/// 服务来源标识色 —— R1 允许出现颜色字面量的两个文件之二。
///
/// 这些不是 UI 角色色，是**服务身份**：用来区分一张内容卡片来自哪个平台。
/// 因此不参与暗色反转，也不参与 `ColorScheme` 构造——放进 `ColorScheme` 会让
/// Material 组件把它们当界面角色用（见 `app/docs/design-system.md` §7.3）。
///
/// 取值说明：只有 [bilibili] 是该平台的官方品牌色。另两个沿用本功能实现时
/// 的原色，**不是**对应平台的官方品牌色；要换成官方色会改变渲染结果，按
/// §6 的分阶段原则属 P3 范围。
abstract final class ServiceBrands() {
  /// 源标识「BILIBILI」，B 站官方品牌蓝。
  static const Color bilibili = Color(0xFF00A1D6);

  /// 源标识「YOUTUBE」。原色 #EF5350，非 YouTube 官方品牌红 #FF0000。
  static const Color youtube = Color(0xFFEF5350);

  /// 源标识「PEERTUBE / RSS」。原色 #FB7299，非 PeerTube 官方色。
  static const Color peerTube = Color(0xFFFB7299);
}
