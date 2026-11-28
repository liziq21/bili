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
      // 标签本身要居中；带前置图标时文字会被推到右侧。
      expect(filterChip.avatar, isNull);

      await tester.tap(chipFinder);
      await tester.pump();

      expect(selectedFilter, filters[1]);
    },
  );

  testWidgets('HomeFilterBar follows theme changes without reselecting', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const _ThemeHarness());
    final lightChip = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, '热门'),
    );
    expect(lightChip.selectedColor, _lightTheme.colorScheme.primary);

    // 只切主题，筛选栏的 delegate 实例与 filters/activeFilterId/height
    // 都不变，shouldRebuild 为假；它仍必须跟随新主题重建。
    tester.state<_ThemeHarnessState>(find.byType(_ThemeHarness)).toggle();
    // MaterialApp 通过 AnimatedTheme 过渡，等动画走完再断言。
    await tester.pumpAndSettle();

    final darkChip = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, '热门'),
    );
    expect(darkChip.selectedColor, _darkTheme.colorScheme.primary);
    expect(darkChip.selectedColor, isNot(_lightTheme.colorScheme.primary));
  });
}

final _lightTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E88E5)),
);
final _darkTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF1E88E5),
    brightness: Brightness.dark,
  ),
);

class const _ThemeHarness() extends StatefulWidget {
  @override
  State<_ThemeHarness> createState() => _ThemeHarnessState();
}

class _ThemeHarnessState() extends State<_ThemeHarness> {
  ThemeData _theme = _lightTheme;

  void toggle() => setState(() => _theme = _darkTheme);

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: _theme,
    home: Scaffold(body: _PersistentFilterBar()),
  );
}

/// 筛选栏宿主：主题变化时重建 sliver，但 filters / activeFilterId / height
/// 全部不变，用来复现「delegate 的 shouldRebuild 输入不变、只有 [Theme]
/// 数据变化」的真实场景。
class const _PersistentFilterBar() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverPersistentHeader(
        pinned: true,
        delegate: HomeFilterBar(
          filters: const [
            HomeFilter(
              id: 'video:popular',
              rawId: 'popular',
              label: '热门',
              kind: HomeFilterKind.videoFeed,
            ),
          ],
          activeFilterId: 'video:popular',
          onSelected: (_) {},
          height: 48.0,
        ),
      ),
    ],
  );
}
