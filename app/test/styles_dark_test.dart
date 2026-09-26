import 'dart:math';

import 'package:app/app_scaffold.dart';
import 'package:app/main.dart';
import 'package:app/styles/colors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Regression tests for the dark-mode palette.
///
/// `AppColors` came from Wonderous as a light-only palette with `isDark`
/// hardcoded to `false`. Every `$styles.colors.*` call site therefore resolved
/// to a light value, which left page backgrounds near-white and text near-black
/// regardless of the active theme. These tests pin both halves of the fix:
/// light values must not drift, and dark mode must actually resolve.
void main() {
  group('AppColors light palette', () {
    // Byte-exact: the light values are the ones that were in use before the
    // fix, and the recorded golden images depend on them. Any drift here
    // shows up as a golden diff.
    final light = AppColors(isDark: false);
    final dark = AppColors(isDark: true);

    test('keeps the original light values unchanged', () {
      expect(light.offWhite, const Color(0xFFF8ECE5));
      expect(light.black, const Color(0xFF1E1B18));
      expect(light.body, const Color(0xFF514F4D));
      expect(light.caption, const Color(0xFF7D7873));
      expect(light.accent1, const Color(0xFFE4935D));
      expect(light.accent2, const Color(0xFFBEABA1));
      expect(light.accent3, const Color(0xFFC47642));
      expect(light.greyStrong, const Color(0xFF272625));
      expect(light.greyMedium, const Color(0xFF9D9995));
    });

    test('swaps foreground and background in dark mode', () {
      // offWhite is used as a page background; black is used as text. They
      // must trade places, otherwise the video screen stays near-white.
      expect(dark.offWhite, const Color(0xFF1E1B18));
      expect(dark.black, const Color(0xFFF8ECE5));
    });

    test('lifts muted text above the dark surface', () {
      // WCAG AA (4.5:1) against #1E1B18:
      // body ~13:1, caption ~6.9:1, accent1 ~6.5:1.
      expect(dark.body, const Color(0xFFE5E0DC));
      expect(dark.caption, const Color(0xFFA8A29D));
      expect(dark.accent1, const Color(0xFFEFA97C));
    });
  });

  group('AppScaffold brightness propagation', () {
    Future<void> pump(WidgetTester tester, ThemeData theme) =>
        tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(size: Size(360, 800)),
            child: MaterialApp(
              theme: theme,
              home: AppScaffold(
                child: Builder(
                  builder: (context) => Text(
                    'probe',
                    style: TextStyle(color: $styles.colors.body),
                  ),
                ),
              ),
            ),
          ),
        );

    testWidgets('resolves the dark palette under a dark theme', (tester) async {
      await pump(tester, ThemeData.dark());
      // `$styles` is a mutable static refreshed during AppScaffold.build(), so
      // it must only be read from inside a Builder that runs afterwards.
      expect($styles.colors.offWhite, const Color(0xFF1E1B18));
      expect($styles.colors.body, const Color(0xFFE5E0DC));
    });

    testWidgets('resolves the light palette under a light theme', (
      tester,
    ) async {
      await pump(tester, ThemeData.light());
      expect($styles.colors.offWhite, const Color(0xFFF8ECE5));
      expect($styles.colors.body, const Color(0xFF514F4D));
    });
  });

  group('scrim surface token', () {
    final light = AppColors(isDark: false);
    final dark = AppColors(isDark: true);

    test('stays dark in both brightnesses', () {
      // 视频占位底、日志面板、渐变遮罩、时长标签底——这些位置两种亮度下
      // 都必须是深色。用相对亮度断言而不是硬编码色值：真正的不变量是
      // 「深色」，不是「恰好是这个 RGB」。
      for (final c in [light.scrim, dark.scrim]) {
        expect(
          c.computeLuminance(),
          lessThan(0.1),
          reason: 'scrim 必须是深色承载面，实际 ${c.toARGB32()}',
        );
      }
    });

    test('dark mode is darker than the page surface', () {
      // 暗色页面里出现一块比周围更亮的承载面会像在发光。
      expect(dark.scrim.computeLuminance(), lessThan(dark.offWhite.computeLuminance()));
    });

    test('carries white foreground above WCAG AA', () {
      // 上面承载的是白字/白图标，必须够读。
      // WCAG 相对亮度对比度：(L_较亮 + 0.05) / (L_较暗 + 0.05)，白色 L = 1.0。
      for (final c in [light.scrim, dark.scrim]) {
        final ratio = (1.0 + 0.05) / (c.computeLuminance() + 0.05);
        expect(ratio, greaterThan(4.5), reason: '白字压 scrim 需 > 4.5:1，实际 $ratio');
      }
    });

    test('differs from black, which stays a foreground token', () {
      // black 是前景语义，暗色下反转为浅色；scrim 是背景语义，恒深。
      // 两者混用是这次缺陷的根因，测试钉住它们的区别。
      expect(dark.black.computeLuminance(), greaterThan(0.5));
      expect(dark.scrim.computeLuminance(), lessThan(0.1));
    });
  });

  group('ColorScheme on-primary foreground', () {
    /// WCAG 相对亮度对比度：两条颜色 whichever 更亮的在上。
    double contrast(Color a, Color b) {
      final la = a.computeLuminance();
      final lb = b.computeLuminance();
      return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
    }

    test('clears WCAG AA against the primary in both brightnesses', () {
      // accent1 在两种亮度下都是浅色（#E4935D / #EFA97C），白色前景只有
      // 2.4:1 / 2.0:1。搜索结果页筛选栏的 FilledButton 就是这个组合，
      // 文字实际读不出来。
      for (final c in [AppColors(isDark: false), AppColors(isDark: true)]) {
        final scheme = c.toThemeData().colorScheme;
        for (final pair in [
          (fg: scheme.onPrimary, bg: scheme.primary),
          (fg: scheme.onSecondary, bg: scheme.secondary),
        ]) {
          final ratio = contrast(pair.fg, pair.bg);
          expect(
            ratio,
            greaterThan(4.5),
            reason:
                'onPrimary/onSecondary 压 accent1 需 > 4.5:1，'
                '实际 $ratio（fg ${pair.fg.toARGB32()} on bg ${pair.bg.toARGB32()}）',
          );
        }
      }
    });

    test('is not the light white it replaced', () {
      // 钉住「不再是白字」：白字那一版虽然也是 bug，但如果哪天有人把
      // accent1 调深了，这条会先于对比度断言提醒他前景色需要重新评估。
      final dark = AppColors(isDark: true);
      expect(dark.toThemeData().colorScheme.onPrimary, isNot(Colors.white));
    });
  });
}
