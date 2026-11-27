import 'package:app/feature/search/common_widgets/filter_bar.dart';
import 'package:app/feature/search/common_widgets/filter_chip_item.dart';
import 'package:app/feature/search/common_widgets/filter_group_section.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:bilibili/bilibili.dart';
import 'package:data/data.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtube/youtube.dart';

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
      await tester.pump();

      expect(selectedValue, isTrue);
    },
  );

  group('sheet height', () {
    Widget host(List<FilterGroup> filters) => MaterialApp(
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        ...GlobalMaterialLocalizations.delegates,
        YoutubeLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: Scaffold(
        body: FilterBar(filters: filters, onChanged: (_) {}),
      ),
    );

    Future<void> openSheet(WidgetTester tester) async {
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();
    }

    void useDesktopWindow(WidgetTester tester) {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    List<FilterGroup> manyGroups() => [
      for (var i = 0; i < 8; i++)
        SingleFilterGroup(
          key: 'group_$i',
          label: '分组 $i',
          options: VideoDurationFilterOption.values,
        ),
    ];

    testWidgets('shrinks to a single filter group instead of a fixed 60%', (
      WidgetTester tester,
    ) async {
      // 回归 LIZ-197：固定 initialChildSize: 0.6 让只有一组条件的弹层
      // 在条件区下方留出约 340px 空白。
      useDesktopWindow(tester);
      await tester.pumpWidget(host(const [VideoDurationFilter()]));
      await openSheet(tester);

      expect(find.byType(BottomSheet), findsOneWidget);
      // 条件组本身必须渲染出来，否则下面的留白断言在空列表上也成立。
      expect(find.byType(FilterGroupSection), findsOneWidget);
      expect(find.byType(FilterChipItem), findsWidgets);
      expect(
        tester.getSize(find.byType(BottomSheet)).height,
        lessThan(900 * 0.5),
        reason: 'one filter group must not reserve 60% of the screen',
      );

      final listBottom = tester.getRect(find.byType(ListView)).bottom;
      final footerTop = tester.getTopLeft(find.byType(FilledButton)).dy;
      expect(
        footerTop - listBottom,
        lessThan(40),
        reason: 'no blank area between the last group and the footer',
      );
    });

    testWidgets('keeps the Material 3 width cap on a wide window', (
      WidgetTester tester,
    ) async {
      // 给 showModalBottomSheet 传 constraints 会顶掉它默认的 640dp 宽度
      // 上限，宽窗口下面板会铺满整个屏幕。
      useDesktopWindow(tester);
      await tester.pumpWidget(host(const [VideoDurationFilter()]));
      await openSheet(tester);

      final sheetSurface = find
          .descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(Material),
          )
          .first;
      expect(tester.getSize(sheetSurface).width, lessThanOrEqualTo(640));
    });

    testWidgets('caps at 90% of the screen and scrolls many groups', (
      WidgetTester tester,
    ) async {
      useDesktopWindow(tester);
      await tester.pumpWidget(host(manyGroups()));
      await openSheet(tester);

      final sheetHeight = tester.getSize(find.byType(BottomSheet)).height;
      expect(sheetHeight, lessThanOrEqualTo(900 * 0.9 + 0.01));
      expect(sheetHeight, greaterThan(900 * 0.5));

      final list = tester.state<ScrollableState>(find.byType(Scrollable));
      expect(list.position.maxScrollExtent, greaterThan(0));

      // 条件区必须真的能滚，只看 maxScrollExtent 在不可滚动的列表上也成立。
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(list.position.pixels, greaterThan(0));
    });

    testWidgets('closes when a scrollable group list is pulled down', (
      WidgetTester tester,
    ) async {
      // 列表独占纵向拖动手势后，外层面板的拖拽关闭收不到手势；条件多到
      // 需要滚动时仍要能下拉关闭。
      useDesktopWindow(tester);
      await tester.pumpWidget(host(manyGroups()));
      await openSheet(tester);

      await tester.drag(find.byType(ListView), const Offset(0, 200));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('closes when a short group list is pulled down', (
      WidgetTester tester,
    ) async {
      useDesktopWindow(tester);
      await tester.pumpWidget(host(const [VideoDurationFilter()]));
      await openSheet(tester);

      await tester.fling(
        find.byType(FilterGroupSection),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
    });
  });

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
      await tester.pump();

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
      await tester.pump();

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
      await tester.pump();

      expect(reported, isFalse);
      expect(haptics, contains('HapticFeedbackType.selectionClick'));
    });
  });
}
