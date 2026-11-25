import 'dart:ui' show ImageByteFormat, SemanticsAction;

import 'package:app/design/design.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:app/ui/video_card.dart';
import 'package:data/data.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
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

  group('pressed state', () {
    // 按住卡片时 `InkWell` 把主题的状态层画在卡片底色之上。这里读取真实渲染
    // 像素，确认状态层只是薄薄一层：按压态下的标题与副标题仍达 `aaText`，
    // 并且与主题算出的叠加结果一致。用的是渲染后的像素而不是 golden，因为
    // 「半透明」不是 golden 能表达的属性。
    for (final brightness in Brightness.values) {
      testWidgets('feed card keeps its text legible while pressed '
          '(${brightness.name})', (WidgetTester tester) async {
        final colors = AppColors(BrandPalette.of(brightness));
        final theme = appThemeData(colors);
        final scheme = theme.colorScheme;
        final stateLayer = theme.highlightColor;
        final boundaryKey = GlobalKey();

        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            localizationsDelegates: const [
              ...AppLocalizations.localizationsDelegates,
              ...GlobalMaterialLocalizations.delegates,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Center(
              child: RepaintBoundary(
                key: boundaryKey,
                child: SizedBox(
                  width: 320,
                  height: 260,
                  child: VideoCard(
                    variant: VideoCardVariant.feed,
                    videoInfoBase: VideoModel(
                      id: 'BV1pressed',
                      title: 'Pressed state',
                      url: 'https://example.com/video/pressed',
                      viewCount: 1280000,
                      duration: 754,
                      creatorProfileName: 'UP',
                    ),
                    onTap: () {},
                  ),
                ),
              ),
            ),
          ),
        );

        // 采样点取封面下沿的留白：那里只有卡片底色，没有文字、头像或角标。
        final thumbnail = tester.getRect(find.byType(AspectRatio));
        final boundaryRect = tester.getRect(find.byKey(boundaryKey));
        final sample = Offset(
          thumbnail.center.dx - boundaryRect.left,
          thumbnail.bottom + 4 - boundaryRect.top,
        );

        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(VideoCard)),
        );
        await tester.pump();
        // 高亮淡入结束、波纹也已淡出后再取像素：此时表面只剩高亮一层。
        await tester.pump(const Duration(seconds: 1));

        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await tester.runAsync(boundary.toImage);
        final data = await tester.runAsync(
          () => image!.toByteData(format: ImageByteFormat.rawRgba),
        );
        final bytes = data!.buffer.asUint8List();
        final index =
            (sample.dy.round() * image!.width + sample.dx.round()) * 4;
        final pressed = Color.fromARGB(
          255,
          bytes[index],
          bytes[index + 1],
          bytes[index + 2],
        );
        image.dispose();

        await gesture.up();
        await tester.pump();

        final surface = scheme.surfaceContainerLow;
        final expected = Color.alphaBlend(stateLayer, surface);

        expect(
          stateLayer.a,
          lessThan(1),
          reason: 'the state layer must not replace the surface',
        );
        expect(
          pressed,
          isNot(surface),
          reason: 'the pressed state layer must be visible',
        );
        // 门槛断言不依赖主题里的具体取值：若状态层退回不透明强调色，
        // 这里的对比度会掉到 1.3:1 以下并失败。
        for (final (label, foreground) in [
          ('title', scheme.onSurface),
          ('subtitle', scheme.onSurfaceVariant),
        ]) {
          final ratio = Contrast.ratio(foreground, pressed);
          expect(
            ratio,
            greaterThanOrEqualTo(Contrast.aaText),
            reason:
                '$label on pressed card actual '
                '${ratio.toStringAsFixed(2)}:1',
          );
        }
        for (final (channel, actual, want) in [
          ('r', pressed.r, expected.r),
          ('g', pressed.g, expected.g),
          ('b', pressed.b, expected.b),
        ]) {
          expect(
            (actual - want).abs(),
            lessThan(0.02),
            reason: '$channel channel differs from the theme state layer',
          );
        }
      });
    }
  });

  testWidgets('a two-line title never overflows a short grid cell', (
    WidgetTester tester,
  ) async {
    // 网格按 childAspectRatio 给出固定高度。单卡 160px 宽、比例 1.0 时，封面
    // 之后只剩约 50px 给两行标题与元信息，标题满行曾让列溢出 3.5px，底部被
    // 卡片圆角裁掉（#645）。
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 160,
              height: 160,
              child: VideoCard(
                videoInfoBase: VideoModel(
                  id: 'BV1overflow',
                  // 只用字体子集覆盖的字：测试里的字面量同样受 golden 字体契约约束。
                  title: '中文标题中文标题中文标题中文标题中文标题中文标题',
                  url: 'https://example.com/video/overflow',
                  viewCount: 12345,
                  uploadDate: DateTime(2026, 11, 20),
                  duration: 600,
                  creatorProfileName: '中文标题中文标题UP主名字',
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.textContaining('中文标题'), findsWidgets);
  });

  testWidgets('a one-line card keeps its title readable in a short cell', (
    WidgetTester tester,
  ) async {
    // 比 [videoCardExtent] 的预算更矮的格子：调用方把标题降到一行，第二行
    // 不会只剩半截（#645）。
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 160,
              height: 145,
              child: VideoCard(
                titleMaxLines: 1,
                videoInfoBase: VideoModel(
                  id: 'BV1tight',
                  title: '中文标题中文标题中文标题中文标题中文标题中文标题',
                  url: 'https://example.com/video/tight',
                  viewCount: 12345,
                  uploadDate: DateTime(2026, 11, 20),
                  duration: 600,
                  creatorProfileName: '中文标题中文标题UP主名字',
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final title = tester.widget<Text>(find.text('中文标题中文标题中文标题中文标题中文标题中文标题'));
    expect(title.maxLines, 1);
  });

  testWidgets('a roomy cell keeps both title lines', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 160,
              height: 260,
              child: VideoCard(
                videoInfoBase: VideoModel(
                  id: 'BV1roomy',
                  title: '中文标题中文标题中文标题中文标题中文标题中文标题',
                  url: 'https://example.com/video/roomy',
                  viewCount: 12345,
                  uploadDate: DateTime(2026, 11, 20),
                  duration: 600,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final title = tester.widget<Text>(find.text('中文标题中文标题中文标题中文标题中文标题中文标题'));
    expect(title.maxLines, 2);
  });
}
