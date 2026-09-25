import 'package:alchemist/alchemist.dart';
import 'package:app/feature/home/bloc/feed_section_state.dart';
import 'package:app/feature/home/widgets/video_feed_section.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:network_image_mock/network_image_mock.dart';

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
}) => SizedBox(
  width: width,
  height: height,
  child: CustomScrollView(
    slivers: [
      VideoFeedSection(
        section: section,
        sourceName: '哔哩哔哩',
        onVideoTap: (_) {},
        onRetry: () {},
        onLoadMore: () {},
      ),
    ],
  ),
);

void main() {
  group('VideoFeedSection golden', () {
    // The grid column count is derived from the incoming sliver width
    // (LayoutSize.fromWidth: <600 -> 1 col, <900 -> 2 cols, else 3), so each
    // scenario pins its own width. This is the guard for the cross-platform
    // responsive layout work.
    goldenTest(
      'renders every status and breakpoint',
      fileName: 'video_feed_section',
      pumpWidget: (tester, widget) async {
        await mockNetworkImagesFor(() async {
          await tester.pumpWidget(
            MaterialApp(
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
            name: 'compact 1 column, populated',
            child: _sectionUnder(
              section: _section(FeedStatus.success, 3),
              width: 380,
              height: 900,
            ),
          ),
          GoldenTestScenario(
            name: 'medium 2 columns, populated',
            child: _sectionUnder(
              section: _section(FeedStatus.success, 6),
              width: 700,
              height: 700,
            ),
          ),
          GoldenTestScenario(
            name: 'expanded 3 columns, populated',
            child: _sectionUnder(
              section: _section(FeedStatus.success, 6),
              width: 1100,
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
