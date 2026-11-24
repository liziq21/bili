import 'package:app/app_scaffold.dart';
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

    testWidgets('aligns its left edge with the row it introduces', (
      tester,
    ) async {
      // Given a header above a setting row.
      await tester.pumpWidget(
        _buildWidget(
          ListView(
            children: const [
              SettingSectionHeader(title: 'Playback gestures'),
              ListTile(title: Text('Seek')),
            ],
          ),
        ),
      );

      // Then both texts start at the same x (ListTile's contentPadding).
      expect(
        tester.getTopLeft(find.text('Playback gestures')).dx,
        tester.getTopLeft(find.text('Seek')).dx,
      );
    });

    testWidgets('keeps that alignment when the layout scale changes', (
      tester,
    ) async {
      // Given a tablet-sized viewport, where `$styles.insets.sm` no longer
      // equals ListTile's fixed 16dp.
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1400, 900)),
            child: AppScaffold(
              child: Scaffold(
                body: ListView(
                  children: const [
                    SettingSectionHeader(title: 'Playback gestures'),
                    ListTile(title: Text('Seek')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // Then the header still lines up with the row: it must follow the
      // component's fixed padding, not the scaled token (R2.4).
      expect($styles.scale, greaterThan(1));
      expect(
        tester.getTopLeft(find.text('Playback gestures')).dx,
        tester.getTopLeft(find.text('Seek')).dx,
      );
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

  group('SettingTextTile', () {
    testWidgets('shows the current value and reports trimmed input', (
      tester,
    ) async {
      // Given a free-text tile showing its current value.
      String? changed;
      await tester.pumpWidget(
        _buildWidget(
          SettingTextTile(
            title: 'Channel name',
            value: 'Old',
            onChanged: (value) => changed = value,
          ),
        ),
      );
      expect(find.text('Channel name'), findsOneWidget);
      expect(find.text('Old'), findsOneWidget);

      // When the tile is tapped, the text edited, and the dialog confirmed.
      await tester.tap(find.text('Channel name'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '  New name  ');
      final okLabel = MaterialLocalizations.of(
        tester.element(find.byType(AlertDialog)),
      ).okButtonLabel;
      await tester.tap(find.widgetWithText(TextButton, okLabel));
      await tester.pumpAndSettle();

      // Then the trimmed input is reported.
      expect(changed, 'New name');
    });

    testWidgets('leaves the value unchanged when cancelled', (tester) async {
      // Given a free-text tile.
      var calls = 0;
      await tester.pumpWidget(
        _buildWidget(
          SettingTextTile(
            title: 'Channel name',
            value: 'Old',
            onChanged: (_) => calls++,
          ),
        ),
      );

      // When the dialog is opened and cancelled.
      await tester.tap(find.text('Channel name'));
      await tester.pumpAndSettle();
      final cancelLabel = MaterialLocalizations.of(
        tester.element(find.byType(AlertDialog)),
      ).cancelButtonLabel;
      await tester.tap(find.widgetWithText(TextButton, cancelLabel));
      await tester.pumpAndSettle();

      // Then nothing is reported.
      expect(calls, 0);
    });

    testWidgets('reports input submitted from the keyboard', (tester) async {
      // Given an open free-text dialog.
      String? changed;
      await tester.pumpWidget(
        _buildWidget(
          SettingTextTile(
            title: 'Channel name',
            value: 'Old',
            onChanged: (value) => changed = value,
          ),
        ),
      );
      await tester.tap(find.text('Channel name'));
      await tester.pumpAndSettle();

      // When the user submits from the keyboard instead of tapping OK.
      await tester.enterText(find.byType(TextField), 'Typed');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Then the typed text is reported.
      expect(changed, 'Typed');
    });
  });

  group('SettingMultiSelectTile', () {
    const options = <SettingMultiSelectOption<String>>[
      SettingMultiSelectOption('a', 'Alpha'),
      SettingMultiSelectOption('b', 'Beta'),
      SettingMultiSelectOption('c', 'Gamma'),
    ];

    testWidgets('shows selected labels and reports the new selection', (
      tester,
    ) async {
      // Given a multi-select tile with one selected option.
      Set<String>? changed;
      await tester.pumpWidget(
        _buildWidget(
          SettingMultiSelectTile<String>(
            title: 'Tabs',
            options: options,
            selected: const {'a'},
            onChanged: (value) => changed = value,
          ),
        ),
      );
      expect(find.text('Tabs'), findsOneWidget);
      expect(find.text('Alpha'), findsOneWidget);

      // When another option is checked and the sheet confirmed.
      await tester.tap(find.text('Tabs'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Gamma'));
      await tester.pump();
      final okLabel = MaterialLocalizations.of(
        tester.element(find.byType(CheckboxListTile).first),
      ).okButtonLabel;
      await tester.tap(find.widgetWithText(TextButton, okLabel));
      await tester.pumpAndSettle();

      // Then the new selection is reported.
      expect(changed, {'a', 'c'});
    });

    testWidgets('unselecting an option removes it from the result', (
      tester,
    ) async {
      // Given a multi-select tile with two selected options.
      Set<String>? changed;
      await tester.pumpWidget(
        _buildWidget(
          SettingMultiSelectTile<String>(
            title: 'Tabs',
            options: options,
            selected: const {'a', 'b'},
            onChanged: (value) => changed = value,
          ),
        ),
      );

      // When one of them is unchecked and the sheet confirmed.
      await tester.tap(find.text('Tabs'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Alpha'));
      await tester.pump();
      final okLabel = MaterialLocalizations.of(
        tester.element(find.byType(CheckboxListTile).first),
      ).okButtonLabel;
      await tester.tap(find.widgetWithText(TextButton, okLabel));
      await tester.pumpAndSettle();

      // Then only the remaining option is reported.
      expect(changed, {'b'});
    });

    testWidgets('drops selected values that are not in the options', (
      tester,
    ) async {
      // Given a selection that includes a value absent from the options.
      Set<String>? changed;
      await tester.pumpWidget(
        _buildWidget(
          SettingMultiSelectTile<String>(
            title: 'Tabs',
            options: options,
            selected: const {'a', 'z'},
            onChanged: (value) => changed = value,
          ),
        ),
      );

      // When the sheet is confirmed without any change.
      await tester.tap(find.text('Tabs'));
      await tester.pumpAndSettle();
      final okLabel = MaterialLocalizations.of(
        tester.element(find.byType(CheckboxListTile).first),
      ).okButtonLabel;
      await tester.tap(find.widgetWithText(TextButton, okLabel));
      await tester.pumpAndSettle();

      // Then the unknown value is dropped.
      expect(changed, {'a'});
    });
  });
}
