import 'dart:ui' show ImageByteFormat, SemanticsAction;

import 'package:app/design/design.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:app/l10n/localization_file/app_localizations_zh.dart';
import 'package:app/ui/metadata_line.dart';
import 'package:app/ui/video_card.dart';
import 'package:data/data.dart';
import 'package:flutter/rendering.dart'
    show RenderParagraph, RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../flutter_test_config.dart' show clearImageCacheDuringTest;
import '../golden/golden_font.dart';

void main() {
  test('formatViewCount keeps the raw count without localizations', () {
    expect(VideoCard.formatViewCount(500), '500');
    expect(VideoCard.formatViewCount(15000), '');
    expect(VideoCard.formatViewCount(null), '');
  });

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
    expect(
      tester
          .renderObject<RenderMetadataLine>(find.byType(MetadataLine))
          .renderedText,
      contains('五盒ll十箱'),
    );
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

      final subtitle = tester.renderObject<RenderMetadataLine>(
        find.byType(MetadataLine),
      );
      expect(
        subtitle.renderedText,
        contains('Creator With Very Long Name Testing Overflow'),
      );
      // 元信息始终单行：换行会让卡片高度算错。单行约 18-20dp，两行就翻倍。
      expect(subtitle.size.height, lessThan(24));

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

      final subtitle = tester.renderObject<RenderMetadataLine>(
        find.byType(MetadataLine),
      );
      expect(subtitle.renderedText, contains('Feed Creator With Long Name'));
      // 元信息始终单行：换行会让卡片高度算错。单行约 18-20dp，两行就翻倍。
      expect(subtitle.size.height, lessThan(24));

      await clearImageCacheDuringTest(tester);
    },
  );

  group('feed more button placement', () {
    // 手机两列网格的卡片只有 164 宽：标题行扣掉 32px 的按钮后每行只剩两三
    // 个字，所以窄卡片让按钮继续压在封面角落，宽卡片才挪进标题行。
    MediaQueryData media(double width) =>
        MediaQueryData(size: Size(width, 600));

    Future<void> pumpCard(
      WidgetTester tester,
      double width, {
      required bool compact,
      required VoidCallback onTap,
      required VoidCallback onMore,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: media(width),
            child: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: width,
                  height: 300,
                  child: VideoCard(
                    variant: VideoCardVariant.feed,
                    compact: compact,
                    videoInfoBase: VideoModel(
                      id: 'BV1placement$width',
                      title: 'A feed card title that wraps over two lines',
                      url: 'https://example.com/video/placement',
                      viewCount: 10000,
                      duration: 600,
                      creatorProfileName: 'Creator',
                    ),
                    onTap: onTap,
                    onMorePressed: onMore,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('sits on the cover corner when the card is narrow', (
      WidgetTester tester,
    ) async {
      var tapped = false;
      var moreTapped = false;
      await pumpCard(
        tester,
        164,
        compact: true,
        onTap: () => tapped = true,
        onMore: () => moreTapped = true,
      );

      final cover = tester.getRect(find.byType(AspectRatio));
      final more = tester.getRect(find.byTooltip('More options'));
      expect(cover.contains(more.center), isTrue);

      await tester.tap(find.byTooltip('More options'));
      expect(moreTapped, isTrue);
      expect(tapped, isFalse);

      await clearImageCacheDuringTest(tester);
    });

    testWidgets('moves into the title row once the card is wide', (
      WidgetTester tester,
    ) async {
      var tapped = false;
      var moreTapped = false;
      await pumpCard(
        tester,
        320,
        compact: false,
        onTap: () => tapped = true,
        onMore: () => moreTapped = true,
      );

      final cover = tester.getRect(find.byType(AspectRatio));
      final more = tester.getRect(find.byTooltip('More options'));
      expect(more.top, greaterThanOrEqualTo(cover.bottom));

      await tester.tap(find.byTooltip('More options'));
      expect(moreTapped, isTrue);
      expect(tapped, isFalse);

      await clearImageCacheDuringTest(tester);
    });
  });

  group('pressed state', () {
    // 按住卡片时 `InkWell` 把主题的状态层画在页面背景之上（Feed 卡片自己
    // 不画表面）。这里读取真实渲染像素，确认状态层只是薄薄一层：按压态下的
    // 标题与副标题仍达 `aaText`，并且与主题算出的叠加结果一致。用的是渲染
    // 后的像素而不是 golden，因为「半透明」不是 golden 能表达的属性。
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
            // 边界包住整个页面而不是卡片：Feed 卡片不画自己的表面，卡片
            // 区域内只有 InkWell 的高亮层，半透明像素在单卡片边界截图里
            // 没有可叠加的背景。
            home: RepaintBoundary(
              key: boundaryKey,
              child: Scaffold(
                body: Center(
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
          ),
        );

        // 采样点取封面下沿的留白：Feed 卡片不画自己的表面，那里露出的是
        // 页面背景，没有文字、头像或角标。
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

        final surface = scheme.surface;
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

  group('card metadata line', () {
    // 用 golden 字体子集排版：Ahem 的每个字形都是 1em 宽，量不出真实卡片
    // 里「统计信息放得下、作者名放不下」这个宽度关系。
    setUpAll(loadGoldenFont);

    final l10n = AppLocalizationsZh();
    final viewsText = l10n.viewsCount(l10n.countCompactKilo('1.0'));
    final dateText = l10n.daysAgo(4);
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

    Future<void> pumpCard(
      WidgetTester tester, {
      required double width,
      VideoCardVariant variant = VideoCardVariant.feed,
    }) async {
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
                child: VideoCard(variant: variant, videoInfoBase: video()),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    /// 卡片里那行元信息。
    RenderMetadataLine metadataLine(WidgetTester tester) =>
        tester.renderObject<RenderMetadataLine>(
          find.descendant(
            of: find.byType(VideoCard),
            matching: find.byType(MetadataLine),
          ),
        );

    testWidgets(
      'drops the date and the creator so the view count stays readable',
      (WidgetTester tester) async {
        // #682：360 宽两列网格的卡片只有 164 宽。三个字段拼成一串再省略时，
        // 被吃掉的正是播放量；改成按优先级丢字段后，播放量必须完整留在行内。
        await pumpCard(tester, width: 164);

        final line = metadataLine(tester);
        expect(line.renderedText, viewsText);
        expect(line.textWasClipped, isFalse);

        await clearImageCacheDuringTest(tester);
      },
    );

    testWidgets('keeps the view count whole before the creator fits', (
      WidgetTester tester,
    ) async {
      await pumpCard(tester, width: 200);

      final line = metadataLine(tester);
      expect(line.renderedText, viewsText);
      expect(line.textWasClipped, isFalse);

      await clearImageCacheDuringTest(tester);
    });

    testWidgets('shows every field on a wide card', (
      WidgetTester tester,
    ) async {
      await pumpCard(tester, width: 400);

      final line = metadataLine(tester);
      expect(
        line.renderedText,
        '$creator${l10n.spacedBullet}$viewsText${l10n.spacedBullet}$dateText',
      );
      expect(line.textWasClipped, isFalse);

      await clearImageCacheDuringTest(tester);
    });

    testWidgets('drops the creator before the view count on a default card', (
      WidgetTester tester,
    ) async {
      // 搜索结果的两列网格用的也是这个变体：作者名比播放量长得多时，先让
      // 作者名让位（#682）。
      await pumpCard(tester, width: 164, variant: VideoCardVariant.defaultCard);

      final line = metadataLine(tester);
      expect(line.renderedText, viewsText);
      expect(line.textWasClipped, isFalse);

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
