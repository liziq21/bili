import 'dart:async';

import 'package:data/data.dart';
import 'package:model/model.dart';

abstract interface class VideoDetailRepository {
  Future<Result<VideoDetail>> getVideoDetail(String id);
  Future<Result<bool>> toggleLike(String id, bool isLiked);
  Future<Result<bool>> toggleFavorite(String id, bool isFavorited);
  Future<Result<bool>> toggleSubscribe(String creatorId, bool isSubscribed);
}

class AppVideoDetailRepository implements VideoDetailRepository {
  @override
  Future<Result<VideoDetail>> getVideoDetail(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final video = VideoModel(
      id: id,
      title: '示例视频：Flutter 高级响应式布局与 Flutter BLoC 架构实战详解 ($id)',
      url: 'https://www.example.com/video/$id',
      thumbnailUrl: 'https://picsum.photos/seed/$id/600/340',
      viewCount: 125800,
      uploadDate: DateTime.now().subtract(const Duration(days: 2)),
      duration: 720,
      desc: '这是一个展示 Flutter 复杂响应式布局与 BLoC 状态管理的示例视频。\n'
          '1. 宽屏双列响应式适配（左侧视频信息，右侧评论区）；\n'
          '2. 窄屏 Tab 页切换；\n'
          '3. 状态与业务解耦及单元测试。',
      creatorProfileName: 'Flutter 开发者社区',
      creatorProfileId: 'creator_1001',
    );

    final creator = CreatorProfile(
      id: 'creator_1001',
      name: 'Flutter 开发者社区',
      thumbnailUrl: 'https://picsum.photos/seed/creator_1001/150/150',
      subscribers: 58200,
      videos: 128,
    );

    final relatedVideos = List.generate(
      6,
      (index) => VideoModel(
        id: 'related_${id}_$index',
        title: '推荐视频 $index：Flutter 性能优化与工程化实践',
        url: 'https://www.example.com/video/related_$index',
        thumbnailUrl: 'https://picsum.photos/seed/related_$index/300/180',
        viewCount: (index + 1) * 23000,
        uploadDate: DateTime.now().subtract(Duration(days: index + 1)),
        duration: 300 + index * 60,
        creatorProfileName: '推荐 UP 主 ${index + 1}',
        creatorProfileId: 'creator_related_$index',
      ),
    );

    final detail = VideoDetail(
      video: video,
      creator: creator,
      likeCount: 6820,
      favoriteCount: 3210,
      shareCount: 950,
      isLiked: false,
      isFavorited: false,
      isSubscribed: false,
      relatedVideos: relatedVideos,
    );

    return Result.ok(detail);
  }

  @override
  Future<Result<bool>> toggleLike(String id, bool isLiked) async {
    return Result.ok(!isLiked);
  }

  @override
  Future<Result<bool>> toggleFavorite(String id, bool isFavorited) async {
    return Result.ok(!isFavorited);
  }

  @override
  Future<Result<bool>> toggleSubscribe(String creatorId, bool isSubscribed) async {
    return Result.ok(!isSubscribed);
  }
}
