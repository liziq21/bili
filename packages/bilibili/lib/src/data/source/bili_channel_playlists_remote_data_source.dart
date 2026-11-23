import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:model/model.dart';

import '../../bili_utils.dart';
import 'bili_playlist_content_remote_data_source.dart';
import 'bili_remote_data_source.dart';

/// B 站频道页合集列表桥接：`NetworkUserPlaylistDataSource.getUserPlaylists`
/// → [ChannelPlaylistsRemoteDataSource]。
///
/// `seasons_series_list` 同时返回合集（`seasons_list`）与系列
/// （`series_list`）。本桥接只返回合集：系列详情走另一端点
/// `/x/series/archives`，当前 app 没有对应能力，混入列表会让点击后打开
/// 错误的合集（详情端点的 `season_id` 与 `series_id` 属于不同命名空间）。
///
/// 返回的 [PlaylistDetail] 只带列表头，`items` 为空；点开后由
/// [BiliPlaylistContentRemoteDataSource] 按 `<mid>:<seasonId>` 拉取条目。
final class const BiliChannelPlaylistsRemoteDataSource({
  required final NetworkUserPlaylistDataSource network,
}) extends ChannelPlaylistsRemoteDataSource with BiliRemoteDataSource {
  @override
  Future<Result<Page<PlaylistDetail>, Exception>> fetchChannelPlaylists({
    required String channelId,
    int page = 1,
    int pageSize = 30,
  }) {
    final mid = int.tryParse(channelId.trim());
    if (mid == null || mid <= 0) {
      return Future.value(
        Result.error(
          Exception('channelId must be a positive integer id: $channelId'),
        ),
      );
    }
    if (page < 1 || pageSize < 1) {
      return Future.value(
        Result.error(Exception('page and pageSize must be positive')),
      );
    }

    return Future.sync(
      () =>
          network.getUserPlaylists(mid: mid, pageNum: page, pageSize: pageSize),
    ).then((response) {
      final lists = response.itemsLists;
      final seasons = lists?.seasonsList ?? const <NetworkBiliPlaylistSeason>[];
      final seriesCount = lists?.seriesList?.length ?? 0;
      final total = lists?.page?.total;
      // 页码以合集+系列的合并总数计算：过滤系列后单页可能没有合集，但后面
      // 的页仍可能有，不能用「本页合集数」判断是否还有下一页。
      final totalPages = total == null
          ? (seasons.length + seriesCount < pageSize ? page : page + 1)
          : ((total + pageSize - 1) ~/ pageSize).clamp(page, 1 << 30);

      return Page<PlaylistDetail>(
        number: page,
        totalPages: totalPages,
        data: [
          for (final season in seasons)
            if (season.meta?.seasonId case final seasonId? when seasonId > 0)
              PlaylistDetail(
                id: NetworkBiliPlaylistRef.format(
                  ownerId: '$mid',
                  playlistId: '$seasonId',
                ),
                title: season.meta?.name ?? '$seasonId',
                description: season.meta?.description,
                coverUrl: normalizeBiliUrl(season.meta?.cover),
                creatorId: '$mid',
                totalCount: season.meta?.total,
              ),
        ],
      );
    }).toResult();
  }
}
