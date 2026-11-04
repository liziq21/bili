import 'package:app/app_scaffold.dart';
import 'package:app/datastore/preferences_data_source.dart';
import 'package:app/feature/video/danmaku/danmaku_settings.dart';
import 'package:app/feature/video/danmaku/danmaku_settings_screen.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

Widget _buildScreen(
  PreferencesDataSource preferences, {
  Locale locale = const Locale('zh'),
}) {
  return Provider<PreferencesDataSource>.value(
    value: preferences,
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AppScaffold(child: DanmakuSettingsScreen()),
    ),
  );
}

void main() {
  late PreferencesDataSource preferences;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    preferences = PreferencesDataSource(
      sharedPreferences: SharedPreferencesAsync(),
    );
  });

  tearDown(() => preferences.dispose());

  testWidgets('renders danmaku settings with persisted defaults', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(_buildScreen(preferences));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(DanmakuSettingsScreen));
    final l10n = AppLocalizations.of(context)!;

    expect(
      find.widgetWithText(AppBar, l10n.danmakuSettingsTitle),
      findsOneWidget,
    );
    expect(find.text(l10n.showDanmaku), findsOneWidget);
    expect(find.text(l10n.regularDanmakuDuration), findsOneWidget);
    expect(find.text(l10n.opacity), findsOneWidget);
    expect(find.text(l10n.fontSize), findsOneWidget);
    expect(find.byType(SwitchListTile), findsOneWidget);
    expect(find.byType(Slider), findsNWidgets(7));
  });

  testWidgets('toggles danmaku switch and persists preference', (tester) async {
    await tester.pumpWidget(_buildScreen(preferences));
    await tester.pumpAndSettle();

    final switchFinder = find.byType(SwitchListTile);
    expect(switchFinder, findsOneWidget);

    final initialSwitch = tester.widget<SwitchListTile>(switchFinder);
    expect(initialSwitch.value, isTrue);

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    final updatedSwitch = tester.widget<SwitchListTile>(switchFinder);
    expect(updatedSwitch.value, isFalse);

    final settings = await DanmakuSettings.load(preferences);
    expect(settings.enabled, isFalse);
  });

  testWidgets('verifies slider semantic labels and tooltips', (tester) async {
    await tester.pumpWidget(_buildScreen(preferences));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(DanmakuSettingsScreen));
    final l10n = AppLocalizations.of(context)!;

    // Verify Semantics wrapper on slider
    final regularDurationSemantics = find.ancestor(
      of: find.byType(Slider).first,
      matching: find.byType(Semantics),
    );
    expect(regularDurationSemantics, findsWidgets);

    final slider = tester.widget<Slider>(find.byType(Slider).first);
    expect(slider.semanticFormatterCallback, isNotNull);
    final formattedValue = slider.semanticFormatterCallback!(slider.value);
    expect(formattedValue, l10n.secondsValue('8.0'));

    // Verify Tooltip on slider tile
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Tooltip &&
            widget.message ==
                '${l10n.regularDanmakuDuration}: ${l10n.secondsValue("8.0")}',
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders in isolated environment without preferences', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: AppScaffold(child: DanmakuSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DanmakuSettingsScreen), findsOneWidget);
    expect(find.byType(SwitchListTile), findsOneWidget);
  });
}
