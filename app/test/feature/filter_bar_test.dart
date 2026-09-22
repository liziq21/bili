import 'package:app/feature/search/common_widgets/filter_bar.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
