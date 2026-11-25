import 'package:app/feature/home/bloc/home_bloc.dart';
import 'package:app/feature/home/home_config.dart';
import 'package:app/feature/home/widgets/video_feed_section.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:app/ui/video_card.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// #662：网格的 `mainAxisExtent` 必须容得下卡片真实的文字块。
///
/// 旧公式用 `fontSize * height * 行数` 估算，既漏掉行高向上取整，也漏掉 CJK
/// 回退字体比 `fontSize * height` 更高的自然行距，于是卡片底部的 Column 在
/// 360 宽两列（以及放大字号）时会溢出零点几到几像素。
void main() {
  VideoModel video() => VideoModel(
    id: 'BV1xx411c7mD',
    title: '测试用的视频标题测试用的视频标题测试用的视频标题',
    url: 'https://example.com/video/1',
    thumbnailUrl: '',
    viewCount: 100000,
    uploadDate: DateTime(2026, 9, 17),
  );

  Future<void> pump(
    WidgetTester tester, {
    required Size size,
    required double textScale,
    required Widget child,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Scaffold(body: child),
      ),
    );
    await tester.pump();
  }

  Widget feed() => CustomScrollView(
    slivers: [
      VideoFeedSection(
        section: FeedSectionState<VideoModel>(
          id: 'video_section',
          title: '热门视频',
          status: FeedStatus.success,
          items: [video(), video()],
        ),
        homeConfig: HomeConfig({}),
        onVideoTap: (_) {},
        onRetry: () {},
        onLoadMore: () {},
      ),
    ],
  );

  Widget defaultGrid(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const columns = 2;
      const spacing = 8.0;
      final cardWidth = (constraints.maxWidth - spacing) / columns;
      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          mainAxisExtent: videoCardExtent(context, cardWidth),
        ),
        itemCount: 2,
        itemBuilder: (context, index) => VideoCard(videoInfoBase: video()),
      );
    },
  );

  for (final width in <double>[320, 360, 390, 411]) {
    for (final scale in <double>[1, 1.5, 2]) {
      testWidgets(
        'feed cards do not overflow at ${width.toInt()} wide, text scale $scale',
        (tester) async {
          await pump(
            tester,
            size: Size(width, 900),
            textScale: scale,
            child: feed(),
          );

          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'default cards do not overflow at ${width.toInt()} wide, text scale $scale',
        (tester) async {
          await pump(
            tester,
            size: Size(width, 900),
            textScale: scale,
            child: Builder(builder: defaultGrid),
          );

          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
