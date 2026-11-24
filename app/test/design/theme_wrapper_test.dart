import 'dart:async';

import 'package:app/design/design.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';

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
        builder: (theme, darkTheme, _) {
          light = theme;
          dark = darkTheme;
          return const SizedBox();
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
    expect(light!.highlightColor, lightScheme.primary);
    expect(dark!.highlightColor, darkScheme.primary);
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
        builder: (theme, darkTheme, _) {
          light = theme;
          dark = darkTheme;
          return const SizedBox();
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
        builder: (theme, darkTheme, _) {
          captured.add(theme);
          return const SizedBox();
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
        builder: (theme, darkTheme, _) {
          light = theme;
          dark = darkTheme;
          return const SizedBox();
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
