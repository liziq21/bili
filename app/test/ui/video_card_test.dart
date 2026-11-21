import 'dart:ui' show SemanticsAction;

import 'package:app/ui/video_card.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../flutter_test_config.dart' show clearImageCacheDuringTest;

void main() {
  testWidgets(
    'VideoCard renders title and view count correctly without error',
    (WidgetTester tester) async {
      final semantics = tester.ensureSemantics();
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
        find.bySemanticsLabel('Test Video Card Title,2026-09-17 00:00:00.000'),
        findsOneWidget,
      );

      await tester.tap(find.byType(VideoCard));
      expect(tapped, isTrue);
      semantics.dispose();
    },
  );

  testWidgets('VideoCard default variant exposes a screen-reader tap action', (
    WidgetTester tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var tapCount = 0;
    final video = VideoModel(
      id: 'BV1semanticsTap',
      title: 'Semantics tap title',
      url: 'https://example.com/video/semantics',
      thumbnailUrl: 'https://example.com/thumb.jpg',
      viewCount: 100,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 250,
            child: VideoCard(videoInfoBase: video, onTap: () => tapCount++),
          ),
        ),
      ),
    );

    final node = tester.getSemantics(find.byType(VideoCard));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

    node.owner!.performAction(node.id, SemanticsAction.tap);
    await tester.pump();

    expect(tapCount, 1);
    semantics.dispose();
    await clearImageCacheDuringTest(tester);
  });

  testWidgets('VideoCard without onTap exposes no screen-reader tap action', (
    WidgetTester tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final video = VideoModel(
      id: 'BV1semanticsDisabled',
      title: 'Semantics disabled title',
      url: 'https://example.com/video/disabled',
      thumbnailUrl: 'https://example.com/thumb.jpg',
      viewCount: 100,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 250,
            child: VideoCard(videoInfoBase: video),
          ),
        ),
      ),
    );

    final node = tester.getSemantics(find.byType(VideoCard));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);

    semantics.dispose();
    await clearImageCacheDuringTest(tester);
  });

  testWidgets('VideoCard feed variant renders badge and creator info', (
    WidgetTester tester,
  ) async {
    final semantics = tester.ensureSemantics();
    bool tapped = false;
    bool moreTapped = false;
    final video = VideoModel(
      id: 'BV1xx411c7mD',
      title: 'Stitch Feed Video Title',
      url: 'https://example.com/video/1',
      thumbnailUrl: 'https://example.com/thumb.jpg',
      viewCount: 79000,
      duration: 557,
      creatorProfileName: '五盒ll十箱',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 380,
            height: 320,
            child: VideoCard(
              variant: VideoCardVariant.feed,
              sourceBadge: 'Bilibili',
              videoInfoBase: video,
              onTap: () {
                tapped = true;
              },
              onMorePressed: () {
                moreTapped = true;
              },
            ),
          ),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel('Bilibili,Stitch Feed Video Title'),
      findsOneWidget,
    );
    expect(find.text('Stitch Feed Video Title'), findsOneWidget);
    expect(find.text('Bilibili'), findsOneWidget);
    expect(find.text('09:17'), findsOneWidget);
    expect(find.byTooltip('Stitch Feed Video Title'), findsOneWidget);
    expect(tapped, isFalse);
    expect(find.textContaining('五盒ll十箱'), findsOneWidget);
    expect(find.byTooltip('More options'), findsOneWidget);

    final moreOptions = find.bySemanticsLabel('More options');
    expect(moreOptions, findsOneWidget);
    final moreOptionsSemantics = tester.getSemantics(moreOptions);
    expect(moreOptionsSemantics.label, 'More options');
    final moreOptionsData = moreOptionsSemantics.getSemanticsData();
    expect(moreOptionsData.flagsCollection.isButton, isTrue);
    expect(moreOptionsData.hasAction(SemanticsAction.tap), isTrue);
    semantics.dispose();

    await tester.tap(find.byTooltip('More options'));
    expect(moreTapped, isTrue);
    await clearImageCacheDuringTest(tester);
  });

  testWidgets(
    'VideoCard enforces ellipsis and maxLines on title and subtitle layout',
    (WidgetTester tester) async {
      final video = VideoModel(
        id: 'BV1layoutTest',
        title:
            'Extremely long video title designed to verify that layout ellipsis '
            'and two-line constraint are strictly preserved without overflow',
        url: 'https://example.com/video/layout',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        viewCount: 123456,
        creatorProfileName: 'Creator With Very Long Name Testing Overflow',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 280,
              height: 240,
              child: VideoCard(videoInfoBase: video),
            ),
          ),
        ),
      );

      final titleWidget = tester.widget<Text>(
        find.text(
          'Extremely long video title designed to verify that layout ellipsis '
          'and two-line constraint are strictly preserved without overflow',
        ),
      );
      expect(titleWidget.maxLines, 2);
      expect(titleWidget.overflow, TextOverflow.ellipsis);

      final subtitleWidget = tester.widget<Text>(
        find.textContaining('Creator With Very Long Name Testing Overflow'),
      );
      expect(subtitleWidget.maxLines, 1);
      expect(subtitleWidget.overflow, TextOverflow.ellipsis);

      await clearImageCacheDuringTest(tester);
    },
  );

  testWidgets(
    'VideoCard feed variant enforces ellipsis and maxLines on title and creator info',
    (WidgetTester tester) async {
      final video = VideoModel(
        id: 'BV1feedLayout',
        title: 'Feed variant extremely long title to assert layout ellipsis and constraints',
        url: 'https://example.com/video/feedLayout',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        viewCount: 999999,
        creatorProfileName: 'Feed Creator With Long Name',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 300,
              child: VideoCard(
                variant: VideoCardVariant.feed,
                videoInfoBase: video,
              ),
            ),
          ),
        ),
      );

      final titleWidget = tester.widget<Text>(
        find.text(
          'Feed variant extremely long title to assert layout ellipsis and constraints',
        ),
      );
      expect(titleWidget.maxLines, 2);
      expect(titleWidget.overflow, TextOverflow.ellipsis);

      final subtitleWidget = tester.widget<Text>(
        find.textContaining('Feed Creator With Long Name'),
      );
      expect(subtitleWidget.maxLines, 1);
      expect(subtitleWidget.overflow, TextOverflow.ellipsis);

      await clearImageCacheDuringTest(tester);
    },
  );
}
