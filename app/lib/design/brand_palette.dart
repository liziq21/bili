import 'package:material_ui/material_ui.dart';

/// 品牌 fallback 色板 —— R1 允许出现颜色字面量的**唯一**文件。
///
/// 这里是全应用色值的**单一来源**（R1）。`AppColors` 只从本类取值，
/// 不持有任何字面量（R4）。
///
/// R1 同时约束本文件的**内容**：不得出现按外部实体（服务源、页面、功能
/// 模块、品牌方）命名的条目，只允许色值常量、`ColorScheme` 构造与
/// `isDark` 分支取值。R8 禁止按服务源开条目。
///
/// 取值沿用接入上游项目时的亮色设计，暗色为逐项配对值。
/// 重新取值的取舍与对比度实测见建立本文件的提交与相关 PR。
@immutable
class const BrandPalette(
  /// Material 组件与自研 token 的共同真值（R4）。
  final ColorScheme scheme,

  /// 恒深承载面：视频占位底、日志面板、渐变遮罩、时长标签底。
  ///
  /// 两种亮度下都必须是深色——上面承载的是浅色文字或图标。Material 的
  /// `ColorScheme` 没有对应角色（其 `scrim` 字段是遮罩层的半透明色，语义
  /// 不同），故由本类直接携带。
  final Color scrim,

  /// 压在 [scrim] 之上的浅色前景。
  final Color onScrim,

  /// 最强前景：浅底上的近黑文字，暗色下反转为深底上的浅色文字。
  ///
  /// 与 [scheme] 的 `onSurface` 并存的第三档前景。存在的依据：现有代码有
  /// black / body / caption 三档文字前景，而 Material 的 `ColorScheme` 只
  /// 提供 `onSurface` 与 `onSurfaceVariant` 两档。合并任一档都会改变渲染
  /// 结果，而 P2 的承诺是零像素变化。
  ///
  /// 不要拿它当容器背景用——需要深底时用 [scrim]。背景与前景在暗色下方向
  /// 相反，共用一个常量必然有一边出错。
  final Color onSurfaceStrong,
) {
  /// 按亮度取对应的一套色板。
  static BrandPalette of(Brightness brightness) =>
      switch (brightness) {
        Brightness.light => _light,
        Brightness.dark => _dark,
      };

  // ── 亮色取值 ────────────────────────────────────────────────────────────
  // 相对亮色 surface #F8ECE5 的对比度按 WCAG AA 门槛选取：
  // accentText 5.0:1（正文）、accentFill 4.0:1（图形/指示器）、
  // onSurfaceVariant 5.0:1（弱化文字）、secondary 3.6:1（次级强调）、
  // outline 3.2:1（分隔线/弱图形）。留有余量，不卡在门槛线上。
  static const Color _accentLight = Color(0xFFB75B1E);
  static const Color _accent2Light = Color(0xFF947666);
  static const Color _accent3Light = Color(0xFFC47642);
  static const Color _surfaceLight = Color(0xFFF8ECE5);
  static const Color _captionLight = Color(0xFF696561);
  static const Color _bodyLight = Color(0xFF514F4D);
  static const Color _greyStrongLight = Color(0xFF272625);
  static const Color _greyMediumLight = Color(0xFF89847F);
  static const Color _scrimLight = Color(0xFF1E1B18);

  // ── 暗色取值：前景与背景互换，弱化色提亮以保住对比度 ──────────────────
  // 相对暗色背景 #1E1B18 的对比度按 WCAG AA（正文 4.5:1）选取：
  // body ≈ 13:1，caption ≈ 6.9:1，accent ≈ 6.5:1。
  static const Color _accentDark = Color(0xFFEFA97C);
  static const Color _accent2Dark = Color(0xFFC9BCB4);
  static const Color _accent3Dark = Color(0xFFD08A55);
  static const Color _surfaceDark = Color(0xFF1E1B18);
  static const Color _captionDark = Color(0xFFA8A29D);
  static const Color _bodyDark = Color(0xFFE5E0DC);
  static const Color _greyStrongDark = Color(0xFF3A3836);
  static const Color _greyMediumDark = Color(0xFF7A7672);
  static const Color _scrimDark = Color(0xFF141210);

  static final BrandPalette _light = BrandPalette(
    ColorScheme(
      brightness: Brightness.light,
      primary: _accentLight,
      onPrimary: Color(0xFF000000),
      primaryContainer: _accentLight,
      onPrimaryContainer: Color(0xFF000000),
      secondary: _accent2Light,
      onSecondary: Color(0xFF000000),
      secondaryContainer: _accent2Light,
      tertiary: _accent3Light,
      onTertiary: Color(0xFF000000),
      surface: _surfaceLight,
      onSurface: _bodyLight,
      onSurfaceVariant: _captionLight,
      // 骨架块/头像底与边框/图标容器在现有代码里同值，故与
      // outlineVariant 共用 _greyStrongLight。P3 若要把两者拆开需重新取值。
      surfaceContainerHighest: _greyStrongLight,
      outline: _greyMediumLight,
      outlineVariant: _greyStrongLight,
      error: Colors.red.shade400,
      onError: Colors.white,
    ),
    _scrimLight,
    Colors.white,
    _scrimLight,
  );

  static final BrandPalette _dark = BrandPalette(
    ColorScheme(
      brightness: Brightness.dark,
      primary: _accentDark,
      onPrimary: _scrimDark,
      primaryContainer: _accentDark,
      onPrimaryContainer: _surfaceLight,
      secondary: _accent2Dark,
      onSecondary: _scrimDark,
      secondaryContainer: _accent2Dark,
      tertiary: _accent3Dark,
      onTertiary: _scrimDark,
      surface: _surfaceDark,
      onSurface: _bodyDark,
      onSurfaceVariant: _captionDark,
      surfaceContainerHighest: _greyStrongDark,
      outline: _greyMediumDark,
      outlineVariant: _greyStrongDark,
      error: Colors.red.shade400,
      onError: Colors.white,
    ),
    _scrimDark,
    Colors.white,
    // 亮色下的最强前景正是暗色下的表面色，两者互为反转。
    _surfaceLight,
  );
}
