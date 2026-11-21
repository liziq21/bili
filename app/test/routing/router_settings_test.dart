import 'package:app/feature/setting/setting_screen.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:app/routing/router.dart';
import 'package:app/routing/routes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDownAll(router.dispose);

  // 标题直接取 l10n：设置各页的标签都已本地化，把英文写死在测试里会在翻译
  // 落地后整片变红。
  String titleFor(AppLocalizations l10n, String path) => switch (path) {
    Routes.settings => l10n.settingsTitle,
    Routes.settingsPlayer => l10n.settingsPlayer,
    Routes.settingsAppearance => l10n.settingsAppearance,
    Routes.settingsHistory => l10n.settingsHistory,
    Routes.settingsLibrary => l10n.settingsLibrary,
    Routes.settingsNotifications => l10n.settingsNotifications,
    Routes.settingsAdvanced => l10n.settingsAdvanced,
    Routes.settingsChannel => l10n.settingsChannel,
    _ => path,
  };

  for (final path in [
    Routes.settings,
    Routes.settingsPlayer,
    Routes.settingsAppearance,
    Routes.settingsHistory,
    Routes.settingsLibrary,
    Routes.settingsNotifications,
    Routes.settingsAdvanced,
    Routes.settingsChannel,
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
        final l10n = AppLocalizations.of(tester.element(find.byType(AppBar)))!;
        expect(
          find.widgetWithText(AppBar, titleFor(l10n, path)),
          findsOneWidget,
        );
        expect(find.byType(NavigationBar), findsNothing);
        expect(find.byType(NavigationRail), findsNothing);
        expect(tester.takeException(), isNull);

        if (path != Routes.settings) {
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle();
        }
        expect(router.state.uri.path, Routes.settings);
        expect(find.byType(SettingScreen), findsOneWidget);
        expect(find.byType(ListTile), findsNWidgets(8));
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    });
  }
}
