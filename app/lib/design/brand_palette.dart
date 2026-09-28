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
class const BrandPalette({
  /// Material 组件与自研 token 的共同真值（R4）。
  required final ColorScheme scheme,

  /// 恒深承载面：视频占位底、日志面板、渐变遮罩、时长标签底。
  ///
  /// 两种亮度下都必须是深色——上面承载的是浅色文字或图标。Material 的
  /// `ColorScheme` 没有对应角色（其 `scrim` 字段是遮罩层的半透明色，语义
  /// 不同），故由本类直接携带。
  required final Color scrim,

  /// 压在 [scrim] 之上的浅色前景。
  required final Color onScrim,

  /// 最强前景：浅底上的近黑文字，暗色下反转为深底上的浅色文字。
  ///
  /// 与 [scheme] 的 `onSurface` 并存的第三档前景。存在的依据：现有代码有
  /// black / body / caption 三档文字前景，而 Material 的 `ColorScheme` 只
  /// 提供 `onSurface` 与 `onSurfaceVariant` 两档。合并任一档都会改变渲染
  /// 结果，而 P2 的承诺是零像素变化。
  ///
  /// 不要拿它当容器背景用——需要深底时用 [scrim]。背景与前景在暗色下方向
  /// 相反，共用一个常量必然有一边出错。
  required final Color onSurfaceStrong,

  /// 强调色，直接压在 [surface] 上的**文字**（`TabBar.labelColor`、时长
  /// 标签、评论区的强调链接等）。
  ///
  /// 与 [scheme] 的 `primary`（`accentFill`，容器底与图形）分档：文字按
  /// WCAG AA 正文 4.5:1 取值，图形按非文本 3.0:1 取值，故必须独立取值——
  /// 亮色下 `primary` 只有 4.00:1，够图形不够文字。`ColorScheme` 无对应
  /// 角色（同 [onSurfaceStrong] 的理由），由本类直接携带。
  required final Color accentText,
}) {
  /// 按亮度取对应的一套色板。
  static BrandPalette of(Brightness brightness) => switch (brightness) {
    Brightness.light => _light,
    Brightness.dark => _dark,
  };

  // ── 亮色取值 ────────────────────────────────────────────────────────────
  // 相对亮色 surface #F8ECE5 的实测对比度（WCAG 2.1 相对亮度公式，见
  // design/contrast.dart 与 test/design/contrast_test.dart 的门禁）：
  //   accentText  5.12:1  正文 4.5:1 门槛，留 0.62 余量
  //   onSurface   7.04:1  正文
  //   onSurfaceVariant 4.99:1  正文，留 0.49 余量
  //   accentFill  4.00:1  图形 3.0:1 门槛（accentText 的浅一档，见下）
  //   secondary   3.59:1  图形
  //   outline     3.20:1  分隔线/弱图形
  // accentText 与 accentFill 同一色相（L 差 6%）：同一强调色在浅色底下做
  // 文字必须比做图形更深，压到 4.5:1 需要的就是这点亮度差。
  static const Color _accentTextLight = Color(0xFF9D4E1A);
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
    scheme: ColorScheme(
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
    scrim: _scrimLight,
    onScrim: Colors.white,
    onSurfaceStrong: _scrimLight,
    accentText: _accentTextLight,
  );

  static final BrandPalette _dark = BrandPalette(
    scheme: ColorScheme(
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
    scrim: _scrimDark,
    onScrim: Colors.white,
    // 亮色下的最强前景正是暗色下的表面色，两者互为反转。
    onSurfaceStrong: _surfaceLight,
    // 暗色 accent 压暗色 surface 已有 8.68:1，两档都过门槛，无需分色。
    accentText: _accentDark,
  );
}
