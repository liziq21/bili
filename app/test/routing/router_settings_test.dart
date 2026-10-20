import 'package:app/feature/setting/setting_screen.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:app/routing/router.dart';
import 'package:app/routing/routes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDownAll(router.dispose);

  for (final (path, title) in [
    (Routes.settings, 'Settings'),
    (Routes.settingsPlayer, 'Player'),
    (Routes.settingsAppearance, 'Appearance'),
    (Routes.settingsHistory, 'History'),
    (Routes.settingsLibrary, 'Library'),
    (Routes.settingsAdvanced, 'Advanced'),
  ]) {
    testWidgets('$path opens without any source or preferences providers', (
      tester,
    ) async {
      // Given the production router, without a media catalog, bloc or storage.
      router.go(path);
      try {
        // When a settings URL is opened directly.
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            locale: const Locale('zh'),
            localizationsDelegates: const [
              ...AppLocalizations.localizationsDelegates,
              ...GlobalMaterialLocalizations.delegates,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        );
        await tester.pumpAndSettle();

        // Then only the requested settings page is visible and usable.
        expect(router.state.uri.path, path);
        expect(find.widgetWithText(AppBar, title), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
        expect(find.byType(NavigationRail), findsNothing);
        expect(tester.takeException(), isNull);

        if (path != Routes.settings) {
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle();
        }
        expect(router.state.uri.path, Routes.settings);
        expect(find.byType(SettingScreen), findsOneWidget);
        expect(find.byType(ListTile), findsNWidgets(5));
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    });
  }
}
