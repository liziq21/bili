import 'package:app/feature/search/common_widgets/filter_bar.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/feature/search/common_widgets/filter_chip_item.dart';

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
        MaterialApp(
          home: Scaffold(
            body: FilterChipItem(
              label: '最新上传',
              isSelected: false,
              onSelected: (val) {
                selectedValue = val;
              },
            ),
          ),
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
}
