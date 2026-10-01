import 'package:app/feature/search/common_widgets/filter_bar.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/feature/search/common_widgets/filter_chip_item.dart';

/// Records the haptic argument of every `HapticFeedback.vibrate` the widget
/// under test sends, so a test can assert on whether feedback was emitted
/// rather than on the absence of an exception.
List<String> recordHaptics() {
  final haptics = <String>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments as String);
        }
        return null;
      });
  addTearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return haptics;
}

Widget chipHost({
  required bool isSelected,
  required FilterChipSelectionMode selectionMode,
  ValueChanged<bool>? onSelected,
}) => MaterialApp(
  home: Scaffold(
    body: FilterChipItem(
      label: '最新上传',
      isSelected: isSelected,
      selectionMode: selectionMode,
      onSelected: onSelected ?? (_) {},
    ),
  ),
);

void main() {
  testWidgets('FilterBar renders IconButton with tooltip', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilterBar(filters: const [], onChanged: (_) {}, title: '筛选条件'),
        ),
      ),
    );

    final iconButtonFinder = find.byType(IconButton);
    expect(iconButtonFinder, findsOneWidget);

    final iconButton = tester.widget<IconButton>(iconButtonFinder);
    expect(iconButton.tooltip, '筛选条件');
  });

  testWidgets(
    'FilterChipItem renders ChoiceChip with tooltip and handles selection',
    (WidgetTester tester) async {
      bool selectedValue = false;

      await tester.pumpWidget(
        chipHost(
          isSelected: false,
          selectionMode: FilterChipSelectionMode.single,
          onSelected: (val) => selectedValue = val,
        ),
      );

      final chipFinder = find.byType(ChoiceChip);
      expect(chipFinder, findsOneWidget);

      final choiceChip = tester.widget<ChoiceChip>(chipFinder);
      expect(choiceChip.tooltip, '最新上传');

      await tester.tap(chipFinder);
      await tester.pumpAndSettle();

      expect(selectedValue, isTrue);
    },
  );

  group('FilterChipItem confirmation haptic', () {
    testWidgets('stays silent when a single-select chip is tapped again', (
      WidgetTester tester,
    ) async {
      final haptics = recordHaptics();

      await tester.pumpWidget(
        chipHost(
          isSelected: true,
          selectionMode: FilterChipSelectionMode.single,
        ),
      );

      // `ChoiceChip` reports `false` for the already-selected chip, and a
      // single-select caller keeps its selection, so nothing changed.
      await tester.tap(find.byType(ChoiceChip));
      await tester.pumpAndSettle();

      expect(haptics, isEmpty);
    });

    testWidgets('fires when a single-select chip is selected', (
      WidgetTester tester,
    ) async {
      final haptics = recordHaptics();

      await tester.pumpWidget(
        chipHost(
          isSelected: false,
          selectionMode: FilterChipSelectionMode.single,
        ),
      );

      await tester.tap(find.byType(ChoiceChip));
      await tester.pumpAndSettle();

      expect(haptics, contains('HapticFeedbackType.selectionClick'));
    });

    testWidgets('fires when a multi-select chip is deselected', (
      WidgetTester tester,
    ) async {
      final haptics = recordHaptics();
      var reported = true;

      await tester.pumpWidget(
        chipHost(
          isSelected: true,
          selectionMode: FilterChipSelectionMode.multiple,
          onSelected: (val) => reported = val,
        ),
      );

      // A multi-select caller removes the option on `false`, so the same
      // gesture that is a no-op under single-select is a real change here.
      await tester.tap(find.byType(ChoiceChip));
      await tester.pumpAndSettle();

      expect(reported, isFalse);
      expect(haptics, contains('HapticFeedbackType.selectionClick'));
    });
  });
}
