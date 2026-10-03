import 'package:app/feature/home/bloc/home_bloc.dart';
import 'package:app/feature/home/widgets/home_filter_bar.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'HomeFilterBar renders chips with tooltips and triggers selection',
    (WidgetTester tester) async {
      HomeFilter? selectedFilter;
      // 只列真实存在的 Feed：筛选项即 Feed 本身，没有聚合项也没有本地功能占位项。
      const filters = [
        HomeFilter(
          id: 'video:popular',
          rawId: 'popular',
          label: '热门',
          kind: HomeFilterKind.videoFeed,
        ),
        HomeFilter(
          id: 'live:liveFeed',
          rawId: 'liveFeed',
          label: '直播',
          kind: HomeFilterKind.liveFeed,
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
                    activeFilterId: 'video:popular',
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

      final chipFinder = find.widgetWithText(FilterChip, '直播');
      expect(chipFinder, findsOneWidget);

      final filterChip = tester.widget<FilterChip>(chipFinder);
      expect(filterChip.tooltip, '直播');

      await tester.tap(chipFinder);
      await tester.pump();

      expect(selectedFilter, filters[1]);
    },
  );
}
