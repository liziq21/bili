import 'package:app/app_scaffold.dart';
import 'package:app/main.dart';
import 'package:app/styles/colors.dart';
import 'package:flutter/widgets.dart';
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
}
