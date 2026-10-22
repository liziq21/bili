import 'package:alchemist/alchemist.dart';
import 'package:app/feature/home/bloc/feed_section_state.dart';
import 'package:app/feature/home/home_config.dart';
import 'package:app/feature/home/widgets/video_feed_section.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:network_image_mock/network_image_mock.dart';

import 'golden_font.dart';

List<VideoModel> _videos(int count) => List.generate(
  count,
  (i) => VideoModel(
    id: 'BV${i.toString().padLeft(2, '0')}',
    title: '第 ${i + 1} 个视频的标题文字',
    url: 'https://www.bilibili.com/video/BV$i',
    thumbnailUrl: 'https://example.com/thumb-$i.jpg',
    viewCount: 1000 * (i + 1),
    duration: 300 + i * 37,
  ),
);

FeedSectionState<VideoModel> _section(FeedStatus status, int count) =>
    FeedSectionState<VideoModel>(
      id: 'popular',
      title: '热门',
      status: status,
      items: status == FeedStatus.loading ? const [] : _videos(count),
    );

Widget _sectionUnder({
  required FeedSectionState<VideoModel> section,
  required double width,
  required double height,
  HomeConfig? homeConfig,
}) => SizedBox(
  width: width,
  height: height,
  child: CustomScrollView(
    slivers: [
      VideoFeedSection(
        section: section,
        homeConfig: homeConfig ?? HomeConfig.defaults(),
        sourceName: '哔哩哔哩',
        onVideoTap: (_) {},
        onRetry: () {},
        onLoadMore: () {},
      ),
    ],
  ),
);

void main() {
  testWidgets('configured columns follow the screen orientation', (
    tester,
  ) async {
    final homeConfig = HomeConfig(
      {},
      gridColumnsPortrait: 4,
      gridColumnsLandscape: 3,
    );
    for (final (size, expected) in [
      (const Size(400, 800), 4),
      (const Size(900, 600), 3),
    ]) {
      final width = size.width;
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: _sectionUnder(
                  section: _section(FeedStatus.success, 6),
                  width: width,
                  height: 600,
                  homeConfig: homeConfig,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      });

      final grid = tester.widget<SliverGrid>(find.byType(SliverGrid));
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(
        delegate.crossAxisCount,
        expected,
        reason: 'orientation for $size should render $expected columns',
      );
    }
  });

  group('VideoFeedSection golden', () {
    // The grid column count is read from HomeConfig based on the screen
    // orientation. The visual scenarios still cover the different feed states
    // and widths, while the widget test above guards the configuration branch.
    goldenTest(
      'renders every status and breakpoint',
      fileName: 'video_feed_section',
      pumpWidget: (tester, widget) async {
        await loadGoldenFont();
        await mockNetworkImagesFor(() async {
          await tester.pumpWidget(
            MaterialApp(
              theme: goldenTestTheme(),
              home: Scaffold(body: Center(child: widget)),
            ),
          );
          await tester.pumpAndSettle();
        });
      },
      builder: () => GoldenTestGroup(
        columns: 1,
        children: [
          GoldenTestScenario(
            name: 'compact width, configured columns, populated',
            child: _sectionUnder(
              section: _section(FeedStatus.success, 3),
              width: 380,
              height: 900,
            ),
          ),
          GoldenTestScenario(
            name: 'medium width, configured columns, populated',
            child: _sectionUnder(
              section: _section(FeedStatus.success, 6),
              width: 700,
              height: 700,
            ),
          ),
          GoldenTestScenario(
            name: 'expanded width, configured columns, populated',
            child: _sectionUnder(
              section: _section(FeedStatus.success, 6),
              width: 960,
              height: 600,
            ),
          ),
          GoldenTestScenario(
            name: 'compact, initial loading skeletons',
            child: _sectionUnder(
              section: _section(FeedStatus.loading, 0),
              width: 380,
              height: 500,
            ),
          ),
          GoldenTestScenario(
            name: 'compact, failure state',
            child: _sectionUnder(
              section: FeedSectionState<VideoModel>(
                id: 'popular',
                title: '热门',
                status: FeedStatus.failure,
                error: Exception('boom'),
              ),
              width: 380,
              height: 400,
            ),
          ),
          GoldenTestScenario(
            name: 'compact, empty state',
            child: _sectionUnder(
              section: _section(FeedStatus.success, 0),
              width: 380,
              height: 400,
            ),
          ),
        ],
      ),
    );
  });
}
