import 'package:app/ui/common/horizontal_wheel_scroll.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// 横向列表：10 张 200 宽的卡片放进 300 宽的视口，一定可以横向滚动。
Widget _horizontalList({int itemCount = 10}) => SizedBox(
  width: 300,
  height: 100,
  child: HorizontalWheelScroll(
    builder: (context, controller) => ListView.builder(
      controller: controller,
      scrollDirection: Axis.horizontal,
      itemCount: itemCount,
      itemBuilder: (context, index) =>
          SizedBox(width: 200, child: Text('card $index')),
    ),
  ),
);

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(
    body: Align(alignment: Alignment.topLeft, child: child),
  ),
);

ScrollableState _scrollableWithAxis(WidgetTester tester, AxisDirection axis) =>
    tester.state<ScrollableState>(
      find.byWidgetPredicate(
        (widget) => widget is Scrollable && widget.axisDirection == axis,
      ),
    );

final _horizontalListView = find.byWidgetPredicate(
  (widget) => widget is ListView && widget.scrollDirection == Axis.horizontal,
);

void main() {
  group('HorizontalWheelScroll', () {
    testWidgets('scrolls the horizontal list on a plain mouse wheel', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_app(_horizontalList()));

      final horizontal = _scrollableWithAxis(tester, AxisDirection.right);
      expect(horizontal.position.pixels, 0);

      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      pointer.hover(tester.getCenter(_horizontalListView));
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, 200)));
      await tester.pump();

      expect(horizontal.position.pixels, greaterThan(0));
    });

    testWidgets('does not scroll the page while the list still moves', (
      WidgetTester tester,
    ) async {
      // 横向列表嵌在纵向页面里：滚轮被横向列表认领后，页面不能再跟着滚，
      // 否则同一格滚轮会同时移动两个列表。
      await tester.pumpWidget(
        _app(
          ListView(
            children: [
              _horizontalList(),
              for (var i = 0; i < 20; i++)
                SizedBox(height: 100, child: Text('row $i')),
            ],
          ),
        ),
      );

      final vertical = _scrollableWithAxis(tester, AxisDirection.down);
      final horizontal = _scrollableWithAxis(tester, AxisDirection.right);

      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      pointer.hover(tester.getCenter(_horizontalListView));
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, 200)));
      await tester.pump();

      expect(horizontal.position.pixels, greaterThan(0));
      expect(vertical.position.pixels, 0);
    });

    testWidgets('falls through to the page once the list is at its end', (
      WidgetTester tester,
    ) async {
      // 列表滚到头之后滚轮应该继续滚页面，而不是在边界处变成死区。
      await tester.pumpWidget(
        _app(
          ListView(
            children: [
              _horizontalList(itemCount: 1),
              for (var i = 0; i < 20; i++)
                SizedBox(height: 100, child: Text('row $i')),
            ],
          ),
        ),
      );

      final vertical = _scrollableWithAxis(tester, AxisDirection.down);
      final horizontal = _scrollableWithAxis(tester, AxisDirection.right);
      expect(horizontal.position.maxScrollExtent, 0);

      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      pointer.hover(tester.getCenter(_horizontalListView));
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, 200)));
      await tester.pump();

      expect(vertical.position.pixels, greaterThan(0));
    });

    testWidgets('leaves Shift+wheel to the scrollable itself', (
      WidgetTester tester,
    ) async {
      // Shift+滚轮由 Scrollable 翻转轴向处理；这里再认领一次会滚两倍。
      await tester.pumpWidget(_app(_horizontalList()));

      final horizontal = _scrollableWithAxis(tester, AxisDirection.right);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      addTearDown(() => tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft));

      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      pointer.hover(tester.getCenter(_horizontalListView));
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, 100)));
      await tester.pump();

      expect(horizontal.position.pixels, 100);
    });
  });
}
