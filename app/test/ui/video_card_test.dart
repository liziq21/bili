import 'dart:ui' show ImageByteFormat, SemanticsAction;

import 'package:app/design/design.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:app/l10n/localization_file/app_localizations_zh.dart';
import 'package:app/ui/video_card.dart';
import 'package:data/data.dart';
import 'package:flutter/rendering.dart'
    show RenderParagraph, RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../flutter_test_config.dart' show clearImageCacheDuringTest;
import '../golden/golden_font.dart';

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

  testWidgets('a grid cell sized by videoCardExtent fits both title lines', (
    WidgetTester tester,
  ) async {
    // 网格项高度来自 [videoCardExtent]，而标题继承 `Material` 的 bodyMedium
    // （行高 1.43）。预算若按裸 TextStyle 量，每行会少算约 4px，第二行就被
    // 卡片圆角裁掉——`takeException` 发现不了，因为 Flexible 让列不溢出。
    const title = '中文标题中文标题中文标题中文标题中文标题中文标题';
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => SizedBox(
                width: 160,
                height: videoCardExtent(context, 160),
                child: VideoCard(
                  videoInfoBase: VideoModel(
                    id: 'BV1extent',
                    title: title,
                    url: 'https://example.com/video/extent',
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
      ),
    );

    final paragraph = tester.renderObject<RenderParagraph>(find.text(title));
    final boxes = paragraph.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: title.length),
    );
    final lineTops = {for (final box in boxes) box.top.round()};
    expect(lineTops, hasLength(2));
    for (final box in boxes) {
      expect(box.bottom, lessThanOrEqualTo(paragraph.size.height + 0.5));
    }
  });

  group('feed card metadata line', () {
    // 用 golden 字体子集排版：Ahem 的每个字形都是 1em 宽，量不出真实卡片
    // 里「统计信息放得下、作者名放不下」这个宽度关系。
    setUpAll(loadGoldenFont);

    final l10n = AppLocalizationsZh();
    final statsText = l10n.viewsWithDate(
      l10n.countCompactKilo('1.0'),
      l10n.daysAgo(4),
    );
    const creator = '一个长名字的创作者';

    VideoModel video() => VideoModel(
      id: 'BV1metadata',
      title: 'A feed card title',
      url: 'https://example.com/video/metadata',
      thumbnailUrl: '',
      viewCount: 10000,
      uploadDate: DateTime.now().subtract(const Duration(days: 4)),
      creatorProfileName: creator,
    );

    Future<void> pumpCard(WidgetTester tester, {required double width}) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: goldenTestTheme(),
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                height: 300,
                child: VideoCard(
                  variant: VideoCardVariant.feed,
                  videoInfoBase: video(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets(
      'gives the whole line to the stats when the creator cannot fit',
      (WidgetTester tester) async {
        // #682：360 宽两列网格的卡片只有 164 宽，作者名 + 统计信息拼成一行时
        // 被省略号吃掉的是统计数字。放不下作者名时整行让给统计信息，播放量
        // 与日期至少从头开始读，而不是排在作者名之后被截断。
        await pumpCard(tester, width: 164);

        expect(find.text(statsText), findsOneWidget);
        expect(find.text(creator), findsNothing);
        // `find.text` 匹配的是 Text 的数据，实际被省略时同样命中；这里直接
        // 看排版结果：播放量那一段必须完整落在行内。
        _expectPrefixVisible(
          tester.renderObject<RenderParagraph>(find.text(statsText)),
          l10n.viewsCount(l10n.countCompactKilo('1.0')),
        );

        await clearImageCacheDuringTest(tester);
      },
    );

    testWidgets('fits the stats fully once the card is wide enough', (
      WidgetTester tester,
    ) async {
      // 432 宽两列网格的卡片是 200 宽：统计信息可以完整排下，作者名让位。
      await pumpCard(tester, width: 200);

      final stats = tester.renderObject<RenderParagraph>(find.text(statsText));
      expect(stats.didExceedMaxLines, isFalse);
      expect(find.text(creator), findsNothing);

      await clearImageCacheDuringTest(tester);
    });

    testWidgets('shows both the creator and the stats on a wide card', (
      WidgetTester tester,
    ) async {
      await pumpCard(tester, width: 400);

      expect(find.text(creator), findsOneWidget);
      final stats = tester.renderObject<RenderParagraph>(find.text(statsText));
      expect(stats.didExceedMaxLines, isFalse);

      await clearImageCacheDuringTest(tester);
    });

    testWidgets('falls back to a person icon instead of the name initial', (
      WidgetTester tester,
    ) async {
      // #685：Feed 不返回头像地址，整屏「名字首字圆」看起来像头像全部加载
      // 失败；统一的人像图标才是「没有头像」的样式。
      await pumpCard(tester, width: 400);

      expect(find.byIcon(AppIcons.avatarFallback), findsOneWidget);
      expect(find.text(creator.substring(0, 1)), findsNothing);

      await clearImageCacheDuringTest(tester);
    });
  });
}

/// 断言 [prefix] 完整落在段落第一行内，而不是被省略号吃掉。
void _expectPrefixVisible(RenderParagraph paragraph, String prefix) {
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: prefix.length),
  );
  expect(boxes, isNotEmpty);
  for (final box in boxes) {
    expect(box.right, lessThanOrEqualTo(paragraph.size.width + 0.5));
  }
}
