import 'package:app/feature/video/common_widgets/video_player_placeholder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets(
    'VideoPlayerPlaceholder renders accessibility tooltips correctly',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: VideoPlayerPlaceholder(title: '测试视频')),
        ),
      );

      // Verify tooltips exist for action buttons
      expect(find.byTooltip('Back'), findsOneWidget);
      expect(find.byTooltip('Play'), findsNWidgets(2));
      expect(find.byTooltip('Switch source'), findsOneWidget);
      expect(find.byTooltip('Fullscreen'), findsOneWidget);

      // Tap play button and verify tooltips update to 'Pause'
      await tester.tap(find.byTooltip('Play').first);
      await tester.pump();

      expect(find.byTooltip('Pause'), findsNWidgets(2));
    },
  );
}
