import 'package:app/ui/video_card.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'VideoCard renders title and view count correctly without error',
    (WidgetTester tester) async {
      bool tapped = false;
      final video = VideoModel(
        id: 'BV1xx411c7mD',
        title: 'Test Video Card Title',
        url: 'https://example.com/video/1',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        viewCount: 100000,
        uploadDate: DateTime(2026, 9, 17),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 250,
              child: VideoCard(
                videoInfoBase: video,
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );

      expect(
        find.bySemanticsLabel(RegExp(r'Test Video Card Title.*100000 观看')),
        findsOneWidget,
      );

      await tester.tap(find.byType(VideoCard));
      expect(tapped, isTrue);
    },
  );
}
