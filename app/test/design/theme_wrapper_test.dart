import 'dart:async';

import 'package:app/design/design.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';

Widget _shell(ThemeData theme, ThemeData darkTheme, ThemeMode themeMode) =>
    MaterialApp(
      theme: theme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SizedBox.shrink(),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void mockAccentColor(Color? color) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(DynamicColorPlugin.channel, (call) async {
          if (call.method == DynamicColorPlugin.accentColorMethodName) {
            return color?.toARGB32();
          }
          return null;
        });
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(DynamicColorPlugin.channel, null);
  });

  testWidgets('rebuilds both themes from the dynamic schemes', (tester) async {
    const accent = Color(0xFF6750A4);
    mockAccentColor(accent);
    ThemeData? light;
    ThemeData? dark;

    await tester.pumpWidget(
      ThemeWrapper(
        useDynamicColor: true,
        themeConfig: ThemeConfig.followSystem,
        builder: (theme, darkTheme, themeMode) {
          light = theme;
          dark = darkTheme;
          return _shell(theme, darkTheme, themeMode);
        },
      ),
    );
    await tester.pump();

    final lightScheme = ColorScheme.fromSeed(seedColor: accent);
    final darkScheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
    );
    expect(light!.colorScheme, lightScheme);
    expect(dark!.colorScheme, darkScheme);
    expect(light!.textSelectionTheme.cursorColor, lightScheme.primary);
    expect(dark!.textSelectionTheme.cursorColor, darkScheme.primary);
    // 按压 / 水波纹状态层是强调色的半透明叠加：不透明的 primary 会替换
    // 卡片底色，把副标题的对比度压到 1.3:1 以下（见 contrast_test.dart）。
    for (final (theme, scheme) in [
      (light!, lightScheme),
      (dark!, darkScheme),
    ]) {
      expect(theme.highlightColor.withValues(alpha: 1), scheme.primary);
      expect(theme.highlightColor.a, lessThan(1));
      expect(theme.splashColor, theme.highlightColor);
    }
  });

  testWidgets('keeps the brand themes when dynamic colors are unavailable', (
    tester,
  ) async {
    mockAccentColor(null);
    ThemeData? light;
    ThemeData? dark;

    await tester.pumpWidget(
      ThemeWrapper(
        useDynamicColor: true,
        themeConfig: ThemeConfig.followSystem,
        builder: (theme, darkTheme, themeMode) {
          light = theme;
          dark = darkTheme;
          return _shell(theme, darkTheme, themeMode);
        },
      ),
    );
    await tester.pump();

    expect(light!.colorScheme, BrandPalette.of(Brightness.light).scheme);
    expect(dark!.colorScheme, BrandPalette.of(Brightness.dark).scheme);
  });

  testWidgets('uses the pre-resolved palette and never flips afterwards', (
    tester,
  ) async {
    const accent = Color(0xFF6750A4);
    final lightScheme = ColorScheme.fromSeed(seedColor: accent);
    final darkScheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
    );
    final captured = <ThemeData>[];

    // The platform answers later with the same palette. A wrapper that
    // subscribed to that answer would rebuild; the pre-resolved path must not.
    mockAccentColor(accent);

    await tester.pumpWidget(
      ThemeWrapper(
        useDynamicColor: true,
        themeConfig: ThemeConfig.followSystem,
        dynamicSchemes: DynamicColorSchemes(
          light: lightScheme,
          dark: darkScheme,
        ),
        builder: (theme, darkTheme, themeMode) {
          captured.add(theme);
          return _shell(theme, darkTheme, themeMode);
        },
      ),
    );
    await tester.pump();

    expect(captured.single.colorScheme, lightScheme);
  });

  testWidgets('keeps the brand palette when pre-resolution found nothing', (
    tester,
  ) async {
    // The platform would answer with an accent color, but startup already
    // resolved "no dynamic color". Switching now would be the mid-session flip
    // this path exists to prevent.
    mockAccentColor(const Color(0xFF6750A4));
    ThemeData? light;
    ThemeData? dark;

    await tester.pumpWidget(
      ThemeWrapper(
        useDynamicColor: true,
        themeConfig: ThemeConfig.followSystem,
        dynamicSchemes: const DynamicColorSchemes(),
        builder: (theme, darkTheme, themeMode) {
          light = theme;
          dark = darkTheme;
          return _shell(theme, darkTheme, themeMode);
        },
      ),
    );
    await tester.pump();

    expect(light!.colorScheme, BrandPalette.of(Brightness.light).scheme);
    expect(dark!.colorScheme, BrandPalette.of(Brightness.dark).scheme);
  });

  test(
    'resolveDynamicColorSchemes builds both schemes from the accent color',
    () async {
      const accent = Color(0xFF6750A4);
      mockAccentColor(accent);

      final schemes = await resolveDynamicColorSchemes();

      expect(schemes.light, ColorScheme.fromSeed(seedColor: accent));
      expect(
        schemes.dark,
        ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark),
      );
    },
  );

  test(
    'resolveDynamicColorSchemes returns empty when the platform has none',
    () async {
      mockAccentColor(null);

      final schemes = await resolveDynamicColorSchemes();

      expect(schemes.light, isNull);
      expect(schemes.dark, isNull);
    },
  );

  test('a stalled core-palette lookup does not restart the budget', () async {
    var accentCalls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(DynamicColorPlugin.channel, (call) async {
          if (call.method == DynamicColorPlugin.accentColorMethodName) {
            accentCalls++;
            return const Color(0xFF6750A4).toARGB32();
          }
          return Completer<int?>().future;
        });

    final stopwatch = Stopwatch()..start();
    final schemes = await resolveDynamicColorSchemes(
      budget: const Duration(milliseconds: 100),
    );
    stopwatch.stop();

    expect(schemes.light, isNull);
    expect(
      accentCalls,
      0,
      reason: 'no budget is left, so the blocking accent lookup must not start',
    );
    expect(stopwatch.elapsed, lessThan(const Duration(milliseconds: 400)));
  });
}
