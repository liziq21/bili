import 'dart:async';

import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:model/model.dart';

import 'bili_remote_data_source.dart';

final class BiliVideoDetailRemoteDataSource({
  required final NetworkVideoDataSource network,
}) extends VideoDetailRemoteDataSource with BiliRemoteDataSource {
  static final RegExp _controlChars = RegExp(r'[\x00-\x1F\x7F]');

  @override
  Future<Result<VideoDetail>> getVideoDetail(String id) async {
    try {
      final sanitizedId = id.replaceAll(_controlChars, '').trim();
      if (sanitizedId.isEmpty) {
        return Result.error(Exception('Video ID cannot be empty'));
      }

      final detailData = await network.getVideoDetail(bvid: sanitizedId);

      NetworkVideoRelation? relation;
      try {
        relation = await network.getVideoRelation(bvid: sanitizedId);
      } catch (_) {
        // Relation call is best-effort
      }

      List<NetworkRelatedVideo> related = [];
      try {
        related = await network.getRelatedVideos(bvid: sanitizedId);
      } catch (_) {
        // Related videos is best-effort
      }

      final video = VideoModel(
        id: detailData.bvid,
        title: detailData.title,
        url: 'https://www.bilibili.com/video/${detailData.bvid}',
        thumbnailUrl: _formatUrl(detailData.pic),
        viewCount: detailData.stat?.view ?? 0,
        uploadDate: DateTime.fromMillisecondsSinceEpoch(
          detailData.pubdate * 1000,
        ),
        duration: detailData.duration,
        desc: detailData.desc,
        creatorProfileName: detailData.owner?.name,
        creatorProfileId: detailData.owner?.mid.toString(),
      );

      final creator = detailData.owner != null
          ? CreatorProfile(
              id: detailData.owner!.mid.toString(),
              name: detailData.owner!.name,
              thumbnailUrl: _formatUrl(detailData.owner!.face),
            )
          : null;

      final relatedVideos = related
          .map(
            (item) => VideoModel(
              id: item.bvid,
              title: item.title ?? '',
              url: 'https://www.bilibili.com/video/${item.bvid}',
              thumbnailUrl: _formatUrl(item.pic),
              viewCount: item.stat?.view,
              uploadDate: item.pubdate != null
                  ? DateTime.fromMillisecondsSinceEpoch(item.pubdate! * 1000)
                  : null,
              duration: item.duration,
              desc: item.desc,
              creatorProfileName: item.owner?.name,
              creatorProfileId: item.owner?.mid.toString(),
            ),
          )
          .toList();

      final detail = VideoDetail(
        video: video,
        creator: creator,
        likeCount: detailData.stat?.like ?? 0,
        favoriteCount: detailData.stat?.favorite ?? 0,
        shareCount: detailData.stat?.share ?? 0,
        isLiked: relation?.like ?? false,
        isFavorited: relation?.favorite ?? false,
        isSubscribed: relation?.attention ?? false,
        relatedVideos: relatedVideos,
      );

      return Result.ok(detail);
    } catch (e) {
      return Result.error(e is Exception ? e : Exception(e.toString()));
    }
  }

  static String _formatUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('//')) return 'https:$url';
    return url;
  }
}
