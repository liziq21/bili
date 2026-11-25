import 'dart:async';

import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:model/model.dart';

import '../../bili_utils.dart';
import 'bili_playlist_content_remote_data_source.dart';
import 'bili_remote_data_source.dart';

final class BiliVideoDetailRemoteDataSource({
  required final NetworkVideoDataSource network,
}) extends VideoDetailRemoteDataSource with BiliRemoteDataSource {
  static final RegExp _controlChars = RegExp(r'[\x00-\x1F\x7F]');

  @override
  Future<Result<VideoDetail, Exception>> getVideoDetail(String id) async {
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
        url: buildBiliWatchUrl(detailData.bvid),
        thumbnailUrl: normalizeBiliUrl(detailData.pic),
        // 缺 stat 与播放量为 0 是两件事：前者是「接口没给」，页头该整段隐藏，
        // 折成 0 会显示一个编造的播放量。
        viewCount: detailData.stat?.view,
        danmakuCount: detailData.stat?.danmaku,
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
              thumbnailUrl: normalizeBiliUrl(detailData.owner!.face),
            )
          : null;

      final relatedVideos = related
          .map(
            (item) => VideoModel(
              id: item.bvid,
              title: item.title ?? '',
              url: buildBiliWatchUrl(item.bvid),
              thumbnailUrl: normalizeBiliUrl(item.pic),
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

      final chapters = await _chaptersOf(network, detailData);
      final playlist = _playlistOf(detailData);

      final detail = VideoDetail(
        video: video,
        creator: creator,
        copyright: _copyrightOf(detailData.copyright),
        likeCount: detailData.stat?.like ?? 0,
        favoriteCount: detailData.stat?.favorite ?? 0,
        shareCount: detailData.stat?.share ?? 0,
        isLiked: relation?.like ?? false,
        isFavorited: relation?.favorite ?? false,
        isSubscribed: relation?.attention ?? false,
        relatedVideos: relatedVideos,
        chapters: chapters,
        playlist: playlist,
      );

      return Result.success(detail);
    } catch (e) {
      return Result.error(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// 投稿类型来自 `/x/web-interface/view` 的 `copyright`：1 自制、2 转载。
  /// 其余取值接口未定义，返回 null 让界面隐藏该段，不猜。
  static VideoCopyright? _copyrightOf(int copyright) => switch (copyright) {
    1 => VideoCopyright.original,
    2 => VideoCopyright.repost,
    _ => null,
  };

  /// 合集来自 `/x/web-interface/view` 的 `ugc_season`。列表标识按
  /// [NetworkBiliPlaylistRef] 的 `<mid>:<seasonId>` 格式编码，因为播放列表
  /// 内容端点同时需要归属用户与合集 id。
  VideoPlaylistRef? _playlistOf(VideoDetailData detail) {
    final season = detail.ugcSeason;
    // 列表标识需要归属 mid；缺它或非正数的合集无法请求内容端点。
    if (season == null || season.id <= 0 || season.mid <= 0) return null;
    final total = season.sections.fold<int>(
      0,
      (sum, section) => sum + section.episodes.length,
    );
    return VideoPlaylistRef(
      id: NetworkBiliPlaylistRef.format(
        ownerId: season.mid.toString(),
        playlistId: season.id.toString(),
      ),
      title: season.title,
      coverUrl: normalizeBiliUrl(season.cover),
      totalCount: total > 0 ? total : null,
    );
  }

  /// 章节来自 `player/v2` 的 `view_points`（视频看点），按第一个分 P 的 cid
  /// 查询：该端点要求 cid，而页面当前播的也是第一个分 P。
  ///
  /// 章节是可选项，查询失败降级为空列表，不让详情请求整体失败——详情页其余
  /// 内容（描述、相关推荐、UP 主）仍然可用。
  Future<List<VideoChapter>> _chaptersOf(
    NetworkVideoDataSource network,
    VideoDetailData detail,
  ) async {
    final cid = detail.pages?.firstOrNull?.cid;
    if (cid == null) return const [];
    try {
      final playerInfo = await network.getPlayerInfo(
        bvid: detail.bvid,
        cid: cid,
      );
      final points = playerInfo.viewPoints ?? const [];
      final chapters = <VideoChapter>[];
      for (final point in points) {
        final start = point.from;
        final title = point.content?.trim() ?? '';
        if (start == null || !start.isFinite || title.isEmpty) continue;
        chapters.add(VideoChapter(startSeconds: start.round(), title: title));
      }
      chapters.sort((a, b) => a.startSeconds.compareTo(b.startSeconds));
      return List.unmodifiable(chapters);
    } catch (_) {
      return const [];
    }
  }
}
