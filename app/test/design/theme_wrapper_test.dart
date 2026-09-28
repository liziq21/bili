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
    await tester.pumpAndSettle();

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
    await tester.pumpAndSettle();

    expect(light!.colorScheme, BrandPalette.of(Brightness.light).scheme);
    expect(dark!.colorScheme, BrandPalette.of(Brightness.dark).scheme);
  });
}
