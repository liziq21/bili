import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:model/model.dart';

import '../../bili_utils.dart';
import '../model/video_model.dart';
import 'bili_remote_data_source.dart';

/// B 站远端播放列表内容桥接：`NetworkUserDataSource.getPlaylistContent` →
/// [PlaylistContentRemoteDataSource]。
///
/// 该端点需要同时给出列表 id 与列表所属用户 `mid`，而
/// [PlaylistContentRemoteDataSource] 只携带平台列表标识，故构造时注入
/// [NetworkBiliPlaylistRef.ownerId] 登记的归属用户。未登记归属用户的列表
/// 无法请求，直接返回错误而不是猜一个 `mid`。
///
/// 一个分页响应可能带多个列表（`seasons_list` / `series_list`）。本桥接按
/// [playlistId] 匹配 `series_id` 或 `season_id`，只取命中的那个列表，
/// 避免把响应里其他列表的条目混进来。
final class const BiliPlaylistContentRemoteDataSource({
  required final NetworkUserDataSource network,
}) extends PlaylistContentRemoteDataSource with BiliRemoteDataSource {
  @override
  Future<Result<Page<PlaylistDetail>, Exception>> fetchPlaylistContent({
    required String playlistId,
    int page = 1,
    int pageSize = 30,
  }) {
    final ref = NetworkBiliPlaylistRef.parse(playlistId);
    if (ref == null) {
      return Future.value(
        Result.error(
          Exception('playlistId must be a positive integer id: $playlistId'),
        ),
      );
    }
    final ownerId = ref.ownerId;
    if (ownerId == null || ownerId <= 0) {
      return Future.value(
        Result.error(
          Exception('playlistId is missing its owner mid: $playlistId'),
        ),
      );
    }
    if (page < 1 || pageSize < 1) {
      return Future.value(
        Result.error(Exception('page and pageSize must be positive')),
      );
    }

    return Future.sync(
      () => network.getPlaylistContent(
        mid: ownerId,
        pageNum: page,
        pageSize: pageSize,
        seasonId: ref.id,
      ),
    ).then((response) {
      final lists = response.itemsLists;
      final series = _findSeries(lists?.seriesList, ref.id);
      final season = _findSeason(lists?.seasonsList, ref.id);
      final archives = series?.archives ?? season?.archives;
      final total = series?.meta?.total ?? season?.meta?.total;
      final totalPages = total == null
          ? (archives == null || archives.length < pageSize ? page : page + 1)
          : ((total + pageSize - 1) ~/ pageSize).clamp(page, 1 << 30);
      final creator = series?.meta?.creator;
      final title = series?.meta?.name ?? season?.meta?.name ?? '${ref.id}';
      final description =
          series?.meta?.description ?? season?.meta?.description;
      final cover = series?.meta?.cover ?? season?.meta?.cover;
      final creatorMid = series?.meta?.mid ?? season?.meta?.mid;

      return Page<PlaylistDetail>(
        number: page,
        totalPages: totalPages,
        data: [
          PlaylistDetail(
            id: '${ref.ownerId}:${ref.id}',
            title: title,
            description: description,
            coverUrl: normalizeBiliUrl(cover),
            creatorName: creator == null || creator.isEmpty ? null : creator,
            creatorId: (creatorMid ?? ownerId).toString(),
            totalCount: total,
            items: [
              for (final item
                  in archives ?? const <NetworkBiliPlaylistVideoItem>[])
                if (item.bvid.isNotEmpty) item.asModel(),
            ],
          ),
        ],
      );
    }).toResult();
  }
}

NetworkBiliPlaylistSeries? _findSeries(
  List<NetworkBiliPlaylistSeries>? seriesList,
  int id,
) {
  if (seriesList == null) return null;
  for (final series in seriesList) {
    if (series.meta?.seriesId == id) return series;
  }
  return null;
}

NetworkBiliPlaylistSeason? _findSeason(
  List<NetworkBiliPlaylistSeason>? seasonsList,
  int id,
) {
  if (seasonsList == null) return null;
  for (final season in seasonsList) {
    if (season.meta?.seasonId == id) return season;
  }
  return null;
}

/// 播放列表平台标识的解析与渲染。
///
/// 列表 id 本身不唯一（合集与收藏夹分属不同命名空间），`seasonId` 请求参数又
/// 必须与所属用户一起给出，因此桥接把 `mid` 编进列表标识：
/// `<mid>:<listId>`。纯数字标识按「只有 id、归属用户未知」解析。
final class NetworkBiliPlaylistRef {
  // ignore: unnecessary_type_name_in_constructor,use_primary_constructors
  NetworkBiliPlaylistRef._();

  /// 解析 [playlistId]；格式非法时返回 `null`。
  static NetworkBiliPlaylistRefData? parse(String playlistId) {
    final normalized = playlistId.trim();
    if (normalized.isEmpty) return null;
    final parts = normalized.split(':');
    if (parts.length == 1) {
      final id = int.tryParse(parts.first);
      return id == null || id <= 0 ? null : NetworkBiliPlaylistRefData(id);
    }
    if (parts.length != 2) return null;
    final ownerId = int.tryParse(parts.first);
    final id = int.tryParse(parts.last);
    if (ownerId == null || ownerId <= 0 || id == null || id <= 0) return null;
    return NetworkBiliPlaylistRefData(id, ownerId);
  }

  /// 用归属用户与列表 id 渲染平台列表标识。
  static String format({required String ownerId, required String playlistId}) =>
      '${ownerId.trim()}:${playlistId.trim()}';
}

/// [NetworkBiliPlaylistRef.parse] 的结果；[ownerId] 为空表示归属用户未知。
final class const NetworkBiliPlaylistRefData(
  final int id, [
  final int? ownerId,
]);
