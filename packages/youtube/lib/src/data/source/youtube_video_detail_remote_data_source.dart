import 'dart:async';

import 'package:data/data.dart';
import 'package:model/model.dart';
import 'package:ypi/ypi.dart';

import '../../youtube_utils.dart';
import 'youtube_remote_data_source.dart';

/// YouTube 视频详情桥接：InnerTube `next` 端点 → [VideoDetail]。
///
/// 只读取主信息（标题、播放量、发布时间、频道、简介）。互动计数、相关视频
/// 与章节不在本次解析范围内，缺失项保持模型默认值，不伪造。
final class const YouTubeVideoDetailRemoteDataSource(
  final YoutubeService _youtubeService,
) extends VideoDetailRemoteDataSource with YouTubeRemoteDataSource {
  static final RegExp _controlChars = RegExp(r'[\x00-\x1F\x7F]');

  @override
  Future<Result<VideoDetail, Exception>> getVideoDetail(String id) async {
    try {
      final videoId = id.replaceAll(_controlChars, '').trim();
      if (videoId.isEmpty) {
        return Result.error(Exception('Video ID cannot be empty'));
      }

      final response = await _youtubeService.getWatchNext(videoId: videoId);
      final owner = response.owner;

      final video = VideoModel(
        id: response.videoId,
        title: response.title ?? '',
        url: buildYoutubeWatchUrl(response.videoId),
        thumbnailUrl: buildYoutubeThumbnailUrl(response.videoId),
        viewCount: parseYoutubeCount(response.viewCountText),
        uploadDate: parseYoutubeRelativeDate(response.publishedTimeText),
        desc: response.description,
        creatorProfileName: owner?.title,
        creatorProfileId: owner?.channelId,
      );

      final creator = owner == null
          ? null
          : CreatorProfile(
              id: owner.channelId,
              name: owner.title ?? '',
              thumbnailUrl: normalizeYoutubeUrl(
                owner.avatar == null || owner.avatar!.thumbnails.isEmpty
                    ? null
                    : owner.avatar!.thumbnails.last.url,
              ),
              subscribers: parseYoutubeCount(owner.subscriberCountText),
            );

      return Result.success(VideoDetail(video: video, creator: creator));
    } catch (error) {
      return Result.error(
        error is Exception ? error : Exception(error.toString()),
      );
    }
  }
}
