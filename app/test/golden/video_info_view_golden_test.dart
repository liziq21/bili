import 'package:alchemist/alchemist.dart';
import 'package:app/data/repository/video_detail_repository.dart';
import 'package:app/feature/video/bloc/video_bloc.dart';
import 'package:app/feature/video/common_widgets/video_info_view.dart';
import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';
import 'package:network_image_mock/network_image_mock.dart';

import 'golden_font.dart';

/// 只为 [VideoBloc] 提供一个能返回固定详情的仓库。
///
/// golden 关心的是「详情已在屏上」的渲染，不是加载流程；加载态与失败态在
/// [VideoInfoView] 里只是两个 Center，没有布局风险，留给 widget 测试。
class const _DetailRepository() implements VideoDetailRepository {
  @override
  Future<Result<VideoDetail>> getVideoDetail(String id) async =>
      Result.ok(_detail);
  @override
  Future<Result<bool>> toggleLike(String id, bool isLiked) async =>
      const Result.ok(true);
  @override
  Future<Result<bool>> toggleFavorite(String id, bool isFavorited) async =>
      const Result.ok(true);
  @override
  Future<Result<bool>> toggleSubscribe(
    String creatorId,
    bool isSubscribed,
  ) async => const Result.ok(true);
  @override
  Future<Result<MediaStream>> getMediaStream(
    String id, {
    int? preferHeight,
  }) async => Result.error(Exception('golden unused'));
}

final VideoDetail _detail = VideoDetail(
  video: VideoModel(
    id: 'BV1m44y1G7rk',
    title: 'Flutter Impeller 渲染引擎深度解析',
    url: 'https://www.bilibili.com/video/BV1m44y1G7rk',
    thumbnailUrl: 'https://example.com/thumb.jpg',
    viewCount: 386000,
    duration: 754,
    desc: '探讨 Flutter 从 Skia 全面转向 Impeller 的底层渲染考量。',
    creatorProfileName: '技术宅小陈',
    creatorProfileId: '123456',
  ),
  creator: const CreatorProfile(
    id: '123456',
    name: '技术宅小陈',
    thumbnailUrl: 'https://example.com/avatar.jpg',
    subscribers: 128000,
  ),
  likeCount: 28600,
  favoriteCount: 9400,
  shareCount: 3100,
);

/// 把 [VideoBloc] 的注入收进一个可复用的包装。
///
/// `VideoInfoView` 的详情态是一整条 [ListView]（viewport）。alchemist 的
/// `GoldenTestGroup` 用 [Table] + [IntrinsicColumnWidth] 排版，会对每个场景
/// 求固有宽度与高度；viewport 不支持返回固有尺寸（`RenderViewport does not
/// support returning intrinsic dimensions`），只给 `maxHeight` 上界不够——
/// Table 仍会去算它。必须像 [video_feed_section_golden_test] 那样用**固定
/// 尺寸**的 [SizedBox] 把 viewport 钉死，Table 拿到的是常量，不再向 viewport
/// 要固有值。
Widget _infoView({required bool withCreator}) => SizedBox(
  width: 360,
  height: withCreator ? 1600 : 900,
  child: BlocProvider<VideoBloc>(
    create: (_) {
      final bloc = VideoBloc(
        repository: withCreator ? _DetailRepository() : _NoCreatorRepository(),
      );
      bloc.add(const LoadVideoDetail('BV1m44y1G7rk'));
      return bloc;
    },
    child: const VideoInfoView(),
  ),
);

class const _NoCreatorRepository() implements VideoDetailRepository {
  @override
  Future<Result<VideoDetail>> getVideoDetail(String id) async => Result.ok(
    VideoDetail(
      video: VideoModel(
        id: 'BV1noCreator',
        title: '没有 UP 主信息的视频',
        url: 'https://www.bilibili.com/video/BV1noCreator',
      ),
    ),
  );
  @override
  Future<Result<bool>> toggleLike(String id, bool isLiked) async =>
      const Result.ok(true);
  @override
  Future<Result<bool>> toggleFavorite(String id, bool isFavorited) async =>
      const Result.ok(true);
  @override
  Future<Result<bool>> toggleSubscribe(
    String creatorId,
    bool isSubscribed,
  ) async => const Result.ok(true);
  @override
  Future<Result<MediaStream>> getMediaStream(
    String id, {
    int? preferHeight,
  }) async => Result.error(Exception('golden unused'));
}

void main() {
  group('VideoInfoView golden', () {
    goldenTest(
      'renders VideoInfoView with detail loaded',
      fileName: 'video_info_view',
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
          // 详情页是一整条 ListView：头部 + UP 主 + 操作按钮 + 摘要 + 关联推荐。
          // 固定高度给足，让所有区块同框，否则 golden 只录到前两块。
          GoldenTestScenario(
            name: 'with creator',
            child: _infoView(withCreator: true),
          ),
          // creator 为 null 时 _CreatorProfileSection 应整体消失，不剩空壳。
          GoldenTestScenario(
            name: 'without creator',
            child: _infoView(withCreator: false),
          ),
        ],
      ),
    );
  });
}
