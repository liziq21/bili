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
      expect(find.byTooltip('返回'), findsOneWidget);
      expect(find.byTooltip('播放'), findsNWidgets(2));
      expect(find.byTooltip('切换'), findsOneWidget);
      expect(find.byTooltip('全屏'), findsOneWidget);

      // Tap play button and verify tooltips update to '暂停'
      await tester.tap(find.byTooltip('播放').first);
      await tester.pump();

      expect(find.byTooltip('暂停'), findsNWidgets(2));
    },
  );
}
