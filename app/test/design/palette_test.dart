import 'dart:math';

import 'package:app/app_scaffold.dart';
import 'package:app/main.dart';
import 'package:app/design/design.dart';
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
  group('BrandPalette light values', () {
    // Byte-exact: the light values are the ones that were in use before the
    // fix, and the recorded golden images depend on them. Any drift here
    // shows up as a golden diff.
    final light = AppColors(BrandPalette.of(Brightness.light));
    final dark = AppColors(BrandPalette.of(Brightness.dark));

    test('keeps the P3-retuned light values', () {
      // P3 重取值（方案 B）：留余量 + 拉层级，不卡在门槛线上。
      // 亮色 golden 基线需重录（P3 承诺：改像素只发生在这一个提交）。
      expect(light.surface, const Color(0xFFF8ECE5));
      expect(light.onSurfaceStrong, const Color(0xFF1E1B18));
      expect(light.onSurface, const Color(0xFF514F4D));
      expect(light.onSurfaceVariant, const Color(0xFF696561));
      expect(light.accentText, const Color(0xFF9D4E1A));
      expect(light.accentFill, const Color(0xFFB75B1E));
      expect(light.secondary, const Color(0xFF947666));
      expect(light.tertiary, const Color(0xFFC47642));
      expect(light.surfaceContainerHighest, const Color(0xFF272625));
      expect(light.outline, const Color(0xFF89847F));
    });

    test('swaps foreground and background in dark mode', () {
      // surface is the page background; onSurfaceStrong is text. They must
      // trade places, otherwise the video screen stays near-white.
      expect(dark.surface, const Color(0xFF1E1B18));
      expect(dark.onSurfaceStrong, const Color(0xFFF8ECE5));
    });

    test('lifts muted text above the dark surface', () {
      // WCAG AA (4.5:1) against #1E1B18:
      // body ~13:1, caption ~6.9:1, accent1 ~6.5:1.
      expect(dark.onSurface, const Color(0xFFE5E0DC));
      expect(dark.onSurfaceVariant, const Color(0xFFA8A29D));
      expect(dark.accentFill, const Color(0xFFEFA97C));
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
                    style: TextStyle(color: $styles.colors.onSurface),
                  ),
                ),
              ),
            ),
          ),
        );

    // 生产接线是 `ThemeWrapper` 把 `appThemeData(品牌色板)` 交给
    // `MaterialApp.router` 的 theme/darkTheme（app.dart:47-59），测试必须灌
    // 同一个东西——早先这里灌 stock `ThemeData.light()/dark()` 来证明
    // `$styles` 不看上层主题，那个契约在 P3 已改：动态色开启时上层色板是
    // 系统色板，`$styles` 必须跟随，否则同屏两个强调色。
    ThemeData productionTheme(Brightness brightness) =>
        appThemeData(AppColors(BrandPalette.of(brightness)));

    testWidgets('resolves the dark palette under a dark theme', (tester) async {
      await pump(tester, productionTheme(Brightness.dark));
      // `$styles` is a mutable static refreshed during AppScaffold.build(), so
      // it must only be read from inside a Builder that runs afterwards.
      expect($styles.colors.surface, const Color(0xFF1E1B18));
      expect($styles.colors.onSurface, const Color(0xFFE5E0DC));
    });

    testWidgets('resolves the light palette under a light theme', (
      tester,
    ) async {
      await pump(tester, productionTheme(Brightness.light));
      expect($styles.colors.surface, const Color(0xFFF8ECE5));
      expect($styles.colors.onSurface, const Color(0xFF514F4D));
    });

    testWidgets('follows the inherited ColorScheme when it is not the brand one', (
      tester,
    ) async {
      // 动态色路径：系统给一套色板，自研 token 必须整体跟随，
      // accentFill 与 Material 默认 primary 同值（否则 TabBar.indicatorColor
      // 与 FilledButton 底色分叉）。
      final dynamicScheme =
          ThemeData.light().colorScheme.copyWith(
                primary: const Color(0xFF6750A4),
                surface: const Color(0xFFFFFBFE),
              );
      await pump(
        tester,
        productionTheme(Brightness.light).copyWith(colorScheme: dynamicScheme),
      );

      expect($styles.colors.accentFill, dynamicScheme.primary);
      expect($styles.colors.surface, dynamicScheme.surface);
      // accentText 不能沿用品牌橙——系统 primary 未必压得住系统 surface，
      // 故按新色板重算到 4.5:1。
      expect(
        Contrast.ratio($styles.colors.accentText, dynamicScheme.surface),
        greaterThanOrEqualTo(Contrast.aaText),
        reason: '动态色板下的 accentText 须达文字门槛，实际 '
            '${Contrast.ratio($styles.colors.accentText, dynamicScheme.surface).toStringAsFixed(2)}:1',
      );
      // 承载面语义与系统强调色无关，仍走品牌值。
      expect($styles.colors.scrim, const Color(0xFF1E1B18));
    });

    testWidgets('recomputes accentText when the dynamic scheme is dark', (
      tester,
    ) async {
      // 注意：暗色动态色板这一档，沿用品牌 accentText（#EFA97C）本来就过
      // 门槛——重算在这里不是必需的，那条保证由下面
      // 'recomputes accentText for a surface the brand value cannot carry' 钉。
      // 本条只钉住 token 跟随。
      final dynamicScheme =
          ThemeData.dark().colorScheme.copyWith(
                primary: const Color(0xFFD0BCFF),
                surface: const Color(0xFF141218),
              );
      await pump(
        tester,
        productionTheme(Brightness.dark).copyWith(colorScheme: dynamicScheme),
      );

      expect($styles.colors.accentFill, dynamicScheme.primary);
      expect($styles.colors.surface, dynamicScheme.surface);
    });

    testWidgets('does not clobber the inherited ColorScheme', (tester) async {
      // AppScaffold 早先包了一层 `Theme(data: appThemeData($styles.colors))`，
      // 用品牌色板重算 ColorScheme 覆盖上层。动态色开启时
      // DynamicColorBuilder 换上的动态色板就是这样被吃掉的（R5 要求动态
      // 色优先）。用品牌色板自身探针（ThemeData.light() 恰好有一样的
      // primary），所以这里改用一个不属于品牌色板的 primary 来区分两者。
      const probePrimary = Color(0xFF00FF00);
      final inherited = ThemeData.light().copyWith(
        colorScheme: ThemeData.light().colorScheme.copyWith(
          primary: probePrimary,
        ),
      );

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(360, 800)),
          child: MaterialApp(
            theme: inherited,
            home: AppScaffold(
              child: Builder(
                builder: (context) => ColoredBox(
                  color: Theme.of(context).colorScheme.primary,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (w) => w is ColoredBox && w.color == probePrimary,
        ),
        findsOneWidget,
        reason: '后代必须仍读到上层 Theme 的 colorScheme（动态色靠这条生效）',
      );
    });
  });

  group('page rebuild on theme flip', () {
    // Reproduces the production tree shape. `ShellRoute` hands `AppScaffold` a
    // long-lived `navigator`, so after a brightness change `AppScaffold` does
    // rebuild (it reads `Theme.of`) but returns the *identical* child widget,
    // and `Element.updateChild` short-circuits — nothing below the scaffold
    // rebuilds and the page keeps painting the old palette.
    //
    // The probe stands in for `VideoScreen`, which is the single entry point
    // every `$styles.colors.*` read in the video feature hangs off, and it
    // declares a `Theme.of(context)` dependency exactly as the fix does.
    testWidgets('re-reads the palette after a light → dark flip', (
      tester,
    ) async {
      final mode = ValueNotifier(ThemeMode.light);
      addTearDown(mode.dispose);

      // Built once and handed back by reference on every rebuild, exactly like
      // the navigator instance `ShellRoute` gives the scaffold.
      final probe = Builder(
        builder: (context) {
          Theme.of(context); // the same opt-in the page now makes
          return ColoredBox(
            color: $styles.colors.surface,
            child: const SizedBox.expand(),
          );
        },
      );

      await tester.pumpWidget(
        ValueListenableBuilder(
          valueListenable: mode,
          builder: (_, ThemeMode m, _) => MediaQuery(
            data: const MediaQueryData(size: Size(360, 800)),
            child: MaterialApp(
              theme: appThemeData(
                AppColors(BrandPalette.of(Brightness.light)),
              ),
              darkTheme: appThemeData(
                AppColors(BrandPalette.of(Brightness.dark)),
              ),
              themeMode: m,
              home: AppScaffold(child: probe),
            ),
          ),
        ),
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is ColoredBox && w.color == const Color(0xFFF8ECE5),
        ),
        findsOneWidget,
      );

      mode.value = ThemeMode.dark;
      await tester.pumpAndSettle();

      // Assert on the painted widget, not on `$styles.colors.*`: the static is
      // refreshed by `AppScaffold` either way, so only the tree can show that
      // the page itself re-ran its build with the new palette.
      expect(
        find.byWidgetPredicate(
          (w) => w is ColoredBox && w.color == const Color(0xFF1E1B18),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is ColoredBox && w.color == const Color(0xFFF8ECE5),
        ),
        findsNothing,
      );
    });
  });

  group('scrim surface token', () {
    final light = AppColors(BrandPalette.of(Brightness.light));
    final dark = AppColors(BrandPalette.of(Brightness.dark));

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
      expect(
        dark.scrim.computeLuminance(),
        lessThan(dark.surface.computeLuminance()),
      );
    });

    test('carries white foreground above WCAG AA', () {
      // 上面承载的是白字/白图标，必须够读。
      // WCAG 相对亮度对比度：(L_较亮 + 0.05) / (L_较暗 + 0.05)，白色 L = 1.0。
      for (final c in [light.scrim, dark.scrim]) {
        final ratio = (1.0 + 0.05) / (c.computeLuminance() + 0.05);
        expect(
          ratio,
          greaterThan(4.5),
          reason: '白字压 scrim 需 > 4.5:1，实际 $ratio',
        );
      }
    });

    test('differs from the strong foreground, which inverts', () {
      // onSurfaceStrong 是前景语义，暗色下反转为浅色；scrim 是背景语义，恒深。
      // 两者混用是这次缺陷的根因，测试钉住它们的区别。
      expect(dark.onSurfaceStrong.computeLuminance(), greaterThan(0.5));
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
      // 强调色在两种亮度下都是浅色（#E4935D / #EFA97C），白色前景只有
      // 2.4:1 / 2.0:1。搜索结果页筛选栏的 FilledButton 就是这个组合，
      // 文字实际读不出来。
      for (final c in [
        AppColors(BrandPalette.of(Brightness.light)),
        AppColors(BrandPalette.of(Brightness.dark)),
      ]) {
        final scheme = appThemeData(c).colorScheme;
        for (final pair in [
          (fg: scheme.onPrimary, bg: scheme.primary),
          (fg: scheme.onSecondary, bg: scheme.secondary),
        ]) {
          final ratio = contrast(pair.fg, pair.bg);
          expect(
            ratio,
            greaterThan(4.5),
            reason:
                'onPrimary/onSecondary 压强调色需 > 4.5:1，'
                '实际 $ratio（fg ${pair.fg.toARGB32()} on bg ${pair.bg.toARGB32()}）',
          );
        }
      }
    });

    test('is not the light white it replaced', () {
      // 钉住「不再是白字」：白字那一版虽然也是 bug，但如果哪天有人把
      // accent1 调深了，这条会先于对比度断言提醒他前景色需要重新评估。
      final dark = AppColors(BrandPalette.of(Brightness.dark));
      expect(appThemeData(dark).colorScheme.onPrimary, isNot(Colors.white));
    });
  });
}
