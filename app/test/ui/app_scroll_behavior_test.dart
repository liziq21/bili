import 'package:flutter/foundation.dart';
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

    for (final (platform, expectedPhysics) in [
      (TargetPlatform.android, isA<ClampingScrollPhysics>()),
      (TargetPlatform.iOS, isA<BouncingScrollPhysics>()),
    ]) {
      testWidgets('getScrollPhysics uses $platform physics', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(useMaterial3: true, platform: platform),
            home: Builder(
              builder: (context) {
                expect(
                  scrollBehavior.getScrollPhysics(context),
                  expectedPhysics,
                );
                return const SizedBox();
              },
            ),
          ),
        );
      });
    }

    testWidgets(
      'buildScrollbar returns RawScrollbar on desktop/web or child on mobile',
      (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                final child = ListView(
                  controller: controller,
                  children: const [Text('test child')],
                );
                final details = ScrollableDetails(
                  direction: AxisDirection.down,
                  controller: controller,
                );
                final widget = scrollBehavior.buildScrollbar(
                  context,
                  child,
                  details,
                );
                final isNativeMobile =
                    !kIsWeb &&
                    (defaultTargetPlatform == TargetPlatform.android ||
                        defaultTargetPlatform == TargetPlatform.iOS);
                if (isNativeMobile) {
                  expect(widget, same(child));
                } else {
                  expect(widget, isA<RawScrollbar>());
                  expect((widget as RawScrollbar).controller, same(controller));
                }
                return widget;
              },
            ),
          ),
        );

        expect(controller.hasClients, isTrue);
      },
      variant: const TargetPlatformVariant({
        TargetPlatform.android,
        TargetPlatform.iOS,
        TargetPlatform.linux,
      }),
    );
  });
}
