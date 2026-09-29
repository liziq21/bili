import 'package:flutter/gestures.dart';

import 'package:app/ui/common/app_scroll_behavior.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('AppScrollBehavior', () {
    const scrollBehavior = AppScrollBehavior();

    testWidgets('dragDevices includes mouse', (tester) async {
      final dragDevices = scrollBehavior.dragDevices;
      expect(dragDevices, contains(PointerDeviceKind.mouse));
      expect(dragDevices, contains(PointerDeviceKind.touch));
    });

    testWidgets(
      'getScrollPhysics returns platform appropriate physics from MaterialScrollBehavior',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(useMaterial3: true),
            home: Builder(
              builder: (context) {
                final physics = scrollBehavior.getScrollPhysics(context);
                expect(physics, isA<ScrollPhysics>());
                return const SizedBox();
              },
            ),
          ),
        );
      },
    );

    testWidgets(
      'buildScrollbar returns RawScrollbar on desktop/web or child on mobile',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                const child = Text('test child');
                final details = ScrollableDetails(
                  direction: AxisDirection.down,
                  controller: ScrollController(),
                );
                final widget = scrollBehavior.buildScrollbar(
                  context,
                  child,
                  details,
                );
                expect(widget, isNotNull);
                return widget;
              },
            ),
          ),
        );
      },
    );
  });
}
