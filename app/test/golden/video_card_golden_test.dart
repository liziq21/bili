import 'package:alchemist/alchemist.dart';
import 'package:app/ui/video_card.dart';
import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:network_image_mock/network_image_mock.dart';

VideoModel _video({
  String id = 'BV1xx411c7mD',
  String title = 'Golden 测试用的视频标题',
  int? viewCount = 1280000,
  int duration = 754,
}) => VideoModel(
  id: id,
  title: title,
  url: 'https://www.bilibili.com/video/$id',
  thumbnailUrl: 'https://example.com/thumb-$id.jpg',
  viewCount: viewCount,
  uploadDate: DateTime(2026, 9, 17),
  duration: duration,
  creatorProfileName: '测试UP主',
  creatorProfileId: '123456',
);

void main() {
  group('VideoCard golden', () {
    goldenTest(
      'renders both variants',
      fileName: 'video_card',
      // bili imports the `material_ui` fork, which ships its own MaterialApp
      // and ThemeData types. Alchemist's built-in scaffolding uses Flutter's
      // material, so the widget tree has to be wrapped with the fork's app.
      pumpWidget: (tester, widget) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(child: widget),
            ),
          ),
        );
      },
      builder: () => GoldenTestGroup(
        columns: 2,
        // VideoCard's column uses Expanded, so it needs a bounded height.
        // Alchemist lays scenarios out in a table with unbounded height, which
        // would trip `RenderFlex children have non-zero flex but incoming
        // height constraints are unbounded`.
        scenarioConstraints: const BoxConstraints(maxWidth: 320, maxHeight: 280),
        children: [
          GoldenTestScenario(
            name: 'default card',
            child: VideoCard(videoInfoBase: _video()),
          ),
          GoldenTestScenario(
            name: 'default card without thumbnail',
            child: VideoCard(
              videoInfoBase: VideoModel(
                id: 'BV1noThumb',
                title: '没有封面的视频',
                url: 'https://www.bilibili.com/video/BV1noThumb',
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'feed variant with badge',
            child: VideoCard(
              videoInfoBase: _video(id: 'BV1feed01'),
              variant: VideoCardVariant.feed,
              sourceBadge: '哔哩哔哩',
              creatorAvatarUrl: 'https://example.com/avatar.jpg',
            ),
          ),
          GoldenTestScenario(
            name: 'feed variant zero views',
            child: VideoCard(
              videoInfoBase: _video(id: 'BV1feed02', viewCount: 0),
              variant: VideoCardVariant.feed,
              sourceBadge: 'YouTube',
            ),
          ),
        ],
      ),
    );
  });

  testWidgets('thumbnail renders the mocked network image', (
    tester,
  ) async {
    await mockNetworkImagesFor(
      () async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 320,
                child: VideoCard(videoInfoBase: _video()),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.byType(CachedNetworkImage), findsWidgets);
      },
    );
  });
}
