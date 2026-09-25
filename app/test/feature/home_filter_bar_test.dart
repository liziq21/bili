import 'package:app/feature/home/bloc/home_bloc.dart';
import 'package:app/feature/home/widgets/home_filter_bar.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'HomeFilterBar renders chips with tooltips and triggers selection',
    (WidgetTester tester) async {
      HomeFilter? selectedFilter;
      const filters = [
        HomeFilter(
          id: 'aggregate:all',
          rawId: 'all',
          label: '全部推荐',
          kind: HomeFilterKind.all,
        ),
        HomeFilter(
          id: 'placeholder:sub',
          rawId: 'sub',
          label: '订阅更新',
          kind: HomeFilterKind.placeholder,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverPersistentHeader(
                  delegate: HomeFilterBar(
                    filters: filters,
                    activeFilterId: 'aggregate:all',
                    onSelected: (filter) {
                      selectedFilter = filter;
                    },
                    height: 48.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(FilterChip), findsNWidgets(2));

      final chipFinder = find.widgetWithText(FilterChip, '订阅更新');
      expect(chipFinder, findsOneWidget);

      final filterChip = tester.widget<FilterChip>(chipFinder);
      expect(filterChip.tooltip, '订阅更新');

      await tester.tap(chipFinder);
      await tester.pump();

      expect(selectedFilter, filters[1]);
    },
  );
}
