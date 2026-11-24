import 'package:app/design/design.dart';
import 'package:app/feature/setting/common_widgets/setting_tiles.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _buildWidget(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      ...AppLocalizations.localizationsDelegates,
      ...GlobalMaterialLocalizations.delegates,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('SettingSectionHeader', () {
    testWidgets('renders the given title', (tester) async {
      await tester.pumpWidget(
        _buildWidget(const SettingSectionHeader(title: 'Playback')),
      );

      expect(find.text('Playback'), findsOneWidget);
    });
  });

  group('SettingSwitchTile', () {
    testWidgets('renders title, subtitle, and current value', (tester) async {
      await tester.pumpWidget(
        _buildWidget(
          SettingSwitchTile(
            title: 'Recording',
            subtitle: 'Keep a local history',
            value: true,
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Recording'), findsOneWidget);
      expect(find.text('Keep a local history'), findsOneWidget);
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isTrue,
      );
    });

    testWidgets('reports the toggled value when tapped', (tester) async {
      bool? reported;
      await tester.pumpWidget(
        _buildWidget(
          SettingSwitchTile(
            title: 'Recording',
            value: true,
            onChanged: (value) => reported = value,
          ),
        ),
      );

      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();

      expect(reported, isFalse);
    });

    testWidgets('shows a tooltip only when one is provided', (tester) async {
      await tester.pumpWidget(
        _buildWidget(
          SettingSwitchTile(
            title: 'Videos',
            value: true,
            tooltip: 'Videos: visible',
            onChanged: (_) {},
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (widget) => widget is Tooltip && widget.message == 'Videos: visible',
        ),
        findsOneWidget,
      );
    });
  });

  group('SettingValueTile', () {
    testWidgets('shows the current value and invokes onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _buildWidget(
          SettingValueTile(
            title: 'Quality',
            subtitle: 'Default video quality',
            value: '1080p',
            onTap: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Quality'), findsOneWidget);
      expect(find.text('1080p'), findsOneWidget);

      await tester.tap(find.text('Quality'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });

  group('SettingPickerOption', () {
    testWidgets('marks the selected option and invokes onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _buildWidget(
          SettingPickerOption(
            title: 'Dark',
            selected: true,
            onTap: () => tapped = true,
          ),
        ),
      );

      expect(tester.widget<ListTile>(find.byType(ListTile)).selected, isTrue);
      expect(find.byIcon(AppIcons.check), findsOneWidget);

      await tester.tap(find.text('Dark'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('does not show a check for an unselected option', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildWidget(
          SettingPickerOption(title: 'Light', selected: false, onTap: () {}),
        ),
      );

      expect(find.byIcon(AppIcons.check), findsNothing);
    });
  });

  group('SettingActionTile', () {
    testWidgets('renders icon, title, subtitle, and chevron', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _buildWidget(
          SettingActionTile(
            icon: AppIcons.danmakuOn,
            title: 'Danmaku settings',
            subtitle: 'Configure danmaku',
            showChevron: true,
            onTap: () => tapped = true,
          ),
        ),
      );

      expect(find.byIcon(AppIcons.danmakuOn), findsOneWidget);
      expect(find.byIcon(AppIcons.chevronRight), findsOneWidget);
      expect(find.text('Danmaku settings'), findsOneWidget);
      expect(find.text('Configure danmaku'), findsOneWidget);

      await tester.tap(find.text('Danmaku settings'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('hides the chevron when disabled', (tester) async {
      await tester.pumpWidget(
        _buildWidget(
          SettingActionTile(
            icon: AppIcons.deleteSweep,
            title: 'Clear cache',
            onTap: () {},
          ),
        ),
      );

      expect(find.byIcon(AppIcons.chevronRight), findsNothing);
    });
  });
}
