import 'package:material_ui/material_ui.dart';

/// 应用色板。
///
/// 这套色值来自 Wonderous（亮色设计）。接入 bili 时 `isDark` 被硬编码为
/// `false`，于是暗色模式下页面背景仍是 `offWhite`、文字仍是近黑的 `black`，
/// 整套暗色模式形同失效。
///
/// 现在 [isDark] 由 `AppScaffold` 从真实的 `Theme.of(context).brightness`
/// 传入，每个常量按亮度取对应值——**所有 `$styles.colors.*` 调用点无需改动**
/// 即可在暗色下正确显示。
class AppColors({
  /// 页面当前是否为暗色。由 `AppStyle` 从 `Theme.of(context).brightness` 传入。
  required final bool isDark,
}) {
  // ── 亮色取值：与接入 Wonderous 时逐字节一致，保证亮色模式零回归 ──────────
  static const _accent1Light = Color(0xFFE4935D);
  static const _accent2Light = Color(0xFFBEABA1);
  static const _accent3Light = Color(0xFFC47642);
  static const _offWhiteLight = Color(0xFFF8ECE5);
  static const _captionLight = Color(0xFF7D7873);
  static const _bodyLight = Color(0xFF514F4D);
  static const _greyStrongLight = Color(0xFF272625);
  static const _greyMediumLight = Color(0xFF9D9995);

  // ── 暗色取值：前景与背景互换，弱化色提亮以保住对比度 ──────────────────
  // 对比度按 WCAG AA（正文 4.5:1）选取，相对暗色背景 #1E1B18：
  // body ≈ 13:1，caption ≈ 6.9:1，accent1 ≈ 6.5:1。
  static const _accent1Dark = Color(0xFFEFA97C);
  static const _accent2Dark = Color(0xFFC9BCB4);
  static const _accent3Dark = Color(0xFFD08A55);
  static const _offWhiteDark = Color(0xFF1E1B18);
  static const _captionDark = Color(0xFFA8A29D);
  static const _bodyDark = Color(0xFFE5E0DC);
  static const _greyStrongDark = Color(0xFF3A3836);
  static const _greyMediumDark = Color(0xFF7A7672);
  // 恒深色板：两种亮度下取值相同。
  static const _scrimLight = Color(0xFF1E1B18);
  static const _scrimDark = Color(0xFF141210);

  Color get accent1 => isDark ? _accent1Dark : _accent1Light;
  Color get accent2 => isDark ? _accent2Dark : _accent2Light;
  Color get accent3 => isDark ? _accent3Dark : _accent3Light;

  /// 页面/面板背景色。暗色下取近黑，这是视频页暗色模式失效的主因。
  Color get offWhite => isDark ? _offWhiteDark : _offWhiteLight;

  /// 弱化文字色（时间戳、标签等）。
  Color get caption => isDark ? _captionDark : _captionLight;

  /// 正文文字色。
  Color get body => isDark ? _bodyDark : _bodyLight;

  Color get greyStrong => isDark ? _greyStrongDark : _greyStrongLight;
  Color get greyMedium => isDark ? _greyMediumDark : _greyMediumLight;

  Color get white => Colors.white;

  /// 强前景色。语义上是「浅底上的文字」，暗色下反转为「深底上的文字」。
  ///
  /// 不要拿它当容器背景用——需要深底时请用 [scrim]。背景与前景是两套语义，
  /// 暗色下二者的方向恰好相反，共用一个常量必然有一边出错。
  Color get black => isDark ? _offWhiteLight : _offWhiteDark;

  /// 恒深色的承载面：视频占位底、日志面板、渐变遮罩、时长标签底。
  ///
  /// 这些位置在两种亮度下都必须是深色——上面承载的是白色文字或图标。
  /// 暗色下比 [offWhite] 再压暗一档，避免深色页面里出现一块比周围更亮的
  /// 「发光」区域。
  Color get scrim => isDark ? _scrimDark : _scrimLight;

  ThemeData toThemeData() {
    /// Create a TextTheme and ColorScheme, that we can use to generate ThemeData
    final TextTheme txtTheme =
        (isDark ? ThemeData.dark() : ThemeData.light()).textTheme;
    final ColorScheme colorScheme = ColorScheme(
      // Map our custom theme to the Material ColorScheme
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: accent1,
      primaryContainer: accent1,
      secondary: accent1,
      secondaryContainer: accent1,
      surface: offWhite,
      onSurface: body,
      onError: Colors.white,
      // onPrimary / onSecondary 压在 accent1 上。accent1 在两种亮度下都是浅色
      // （#E4935D / #EFA97C），白色前景只有 2.4:1 / 2.0:1，达不到 WCAG AA
      // 的 4.5:1——搜索结果页筛选栏那个 FilledButton 就是这个组合。
      //
      // 用 [scrim] 而不是 [black]：[black] 是前景语义，暗色下会反转为浅色，
      // 压在这里就看不见了；[scrim] 恒深，两种亮度下都是 7.0:1 / 9.7:1。
      onPrimary: scrim,
      onSecondary: scrim,
      error: Colors.red.shade400,
    );

    /// Now that we have ColorScheme and TextTheme, we can create the ThemeData
    /// Also add on some extra properties that ColorScheme seems to miss
    final t = ThemeData.from(textTheme: txtTheme, colorScheme: colorScheme)
        .copyWith(
          textSelectionTheme: TextSelectionThemeData(cursorColor: accent1),
          highlightColor: accent1,
        );

    /// Return the themeData which MaterialApp can now use
    return t;
  }
}
