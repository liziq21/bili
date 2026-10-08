import 'package:alchemist/alchemist.dart';
import 'package:app/feature/search/common_widgets/filter_bar.dart';
import 'package:app/feature/search/common_widgets/filter_group_section.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'golden_font.dart';

/// 测试用的筛选选项。[FilterOption] 是 abstract interface，仓内各源各自实现，
/// golden 只需要一个能进 chip 的最小实现。
class const _Option(@override final String label) implements FilterOption {
  @override
  String get value => label;
}

void main() {
  group('FilterBar golden', () {
    goldenTest(
      'renders collapsed FilterBar',
      fileName: 'filter_bar',
      pumpWidget: (tester, widget) async {
        await loadGoldenFont();
        await tester.pumpWidget(
          MaterialApp(
            theme: goldenTestTheme(),
            home: Scaffold(body: Center(child: widget)),
          ),
        );
        await tester.pumpAndSettle();
      },
      builder: () => GoldenTestGroup(
        columns: 1,
        scenarioConstraints: const BoxConstraints(maxWidth: 360),
        children: [
          // FilterBar 折叠态只是一个 IconButton。单留一帧证明图标与 tooltip
          // 宿主正常；弹层内容在下面那个 golden 里。
          GoldenTestScenario(
            name: 'collapsed icon button',
            child: FilterBar(filters: const [], onChanged: (_) {}),
          ),
          GoldenTestScenario(
            name: 'custom title',
            child: FilterBar(
              filters: const [],
              onChanged: (_) {},
              title: '高级筛选',
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'renders filter group section variants',
      fileName: 'filter_bar_sheet',
      pumpWidget: (tester, widget) async {
        await loadGoldenFont();
        await tester.pumpWidget(
          MaterialApp(
            theme: goldenTestTheme(),
            home: Scaffold(body: Center(child: widget)),
          ),
        );
        await tester.pumpAndSettle();
      },
      // 弹层由三层 Flex 叠成：DraggableScrollableSheet 的 FractionallySizedBox
      // 只给 Column 0.6 倍可用高度，而 ListView 用 sheet 传入的 scrollController
      // 时按内容全高占位，Expanded 压不住它——内容超高时 Column 必然溢出，
      // 真机只是被 sheet 裁掉看不见，golden 里取景的就是裁不掉的那部分。
      // 所以这里不 tap 弹层，直接渲染弹层的内容构件 FilterGroupSection：
      // 它是 public 类，三种分支各自一帧，是弹层里唯一有视觉风险的部分。
      // 弹层的打开/回写行为由 test/feature/filter_bar_test.dart 覆盖。
      builder: () => GoldenTestGroup(
        columns: 1,
        scenarioConstraints: const BoxConstraints(maxWidth: 360),
        children: [
          GoldenTestScenario(
            name: 'single group with selection',
            child: FilterGroupSection(
              group: SingleFilterGroup(
                key: 'duration',
                label: '时长',
                options: [_Option('全部'), _Option('10分钟以下'), _Option('30分钟以上')],
                selection: _Option('全部'),
              ),
              onChanged: (_) {},
            ),
          ),
          GoldenTestScenario(
            name: 'multi group with selections',
            child: FilterGroupSection(
              group: MultiFilterGroup(
                key: 'zone',
                label: '分区',
                options: [_Option('科技'), _Option('生活'), _Option('音乐')],
                selections: {_Option('科技')},
              ),
              onChanged: (_) {},
            ),
          ),
          GoldenTestScenario(
            name: 'date range group unset',
            child: FilterGroupSection(
              group: DateRangeFilterGroup(key: 'date', label: '发布时间'),
              onChanged: (_) {},
            ),
          ),
        ],
      ),
    );
  });
}
