import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Renders a couple of template keys through the real localization delegates so
/// the assertion covers the ARB -> generated -> widget path, not just a direct
/// `AppLocalizationsEn()` lookup.
Widget _app(Locale locale) => MaterialApp(
  locale: locale,
  localizationsDelegates: const [
    ...AppLocalizations.localizationsDelegates,
    ...GlobalMaterialLocalizations.delegates,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Builder(
    builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      return Column(
        children: [
          Text('${l10n.nothingFound}|${l10n.newPlaylist}'),
          Text(
            '${l10n.actionSelectAll}|${l10n.actionDeselect}|'
            '${l10n.selectionSelected(3)}',
          ),
        ],
      );
    },
  ),
);

void main() {
  group('locale resolution', () {
    testWidgets('en locale renders the English template copy', (tester) async {
      // Given the app's delegates and an English device locale.
      await tester.pumpWidget(_app(const Locale('en')));

      // Then the template ARB (English) values are rendered, not Chinese.
      expect(find.text('Nothing found|New playlist'), findsOneWidget);
      expect(find.text('Select All|Deselect|3 selected'), findsOneWidget);
    });

    testWidgets('zh locale renders the Chinese translations', (tester) async {
      // Given the app's delegates and a Chinese device locale.
      await tester.pumpWidget(_app(const Locale('zh')));

      // Then the Chinese ARB values are rendered.
      expect(find.text('未找到内容|新建播放列表'), findsOneWidget);
      expect(find.text('全选|取消全选|已选择 3 项'), findsOneWidget);
    });
  });
}
