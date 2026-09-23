import 'package:app/feature/home/bloc/home_bloc.dart';
import 'package:app/feature/home/widgets/home_filter_bar.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets(
    'HomeFilterBar renders FilterChips with tooltip and triggers callback on tap',
    (WidgetTester tester) async {
      bool selected = false;
      HomeFilter? selectedFilter;

      const filters = [
        HomeFilter(
          id: 'bilibili:all',
          rawId: 'all',
          label: '全部',
          kind: HomeFilterKind.videoFeed,
        ),
        HomeFilter(
          id: 'bilibili:hot',
          rawId: 'hot',
          label: '热门',
          kind: HomeFilterKind.videoFeed,
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
                    activeFilterId: 'bilibili:all',
                    onSelected: (filter) {
                      selected = true;
                      selectedFilter = filter;
                    },
                    height: 48,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final chipFinder = find.byType(FilterChip);
      expect(chipFinder, findsNWidgets(2));

      final firstChip = tester.widget<FilterChip>(chipFinder.first);
      expect(firstChip.tooltip, '切换至全部');

      final secondChip = tester.widget<FilterChip>(chipFinder.at(1));
      expect(secondChip.tooltip, '切换至热门');

      final platformCalls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            platformCalls.add(call);
          });
      try {
        await tester.tap(chipFinder.at(1));
        await tester.pump();
      } finally {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      }

      expect(selected, isTrue);
      expect(selectedFilter?.id, 'bilibili:hot');
      expect(
        platformCalls,
        contains(
          isA<MethodCall>()
              .having((call) => call.method, 'method', 'HapticFeedback.vibrate')
              .having(
                (call) => call.arguments,
                'arguments',
                'HapticFeedbackType.selectionClick',
              ),
        ),
      );
    },
  );
}
