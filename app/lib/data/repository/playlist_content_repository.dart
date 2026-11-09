import 'package:data/data.dart';
import 'package:model/model.dart';

/// 远端播放列表内容 Repository 接口
///
/// 提供获取播放列表详情（信息头 + 条目列表 + 分页）与整列表抓取能力。
abstract interface class PlaylistContentRepository() {
  /// 获取播放列表一页内容（含列表信息头）。
  ///
  /// [playlistId] 为平台列表标识（含归属用户，如 `2:12345`）；[page] 从 1 开始。
  Future<Result<Page<PlaylistDetail>, Exception>> fetchPlaylistContent({
    required String playlistId,
    int page = 1,
    int pageSize = 30,
  });

  /// 抓取播放列表的全部条目，逐页遍历直到完成或中断。
  ///
  /// 返回的 [FullPlaylistFetchResult] 包含所有去重条目、是否完成、可用于恢复的
  /// 下一页号与可能的错误。[onProgress] 在抓取结束后回调一次，参数为已获取条目数。
  Future<FullPlaylistFetchResult<VideoModel>> fetchAll({
    required String playlistId,
    int pageSize = 30,
    int startPage = 1,
    void Function(int fetchedCount)? onProgress,
  });
}

/// [PlaylistContentRepository] 的默认应用实现
///
/// 依赖可选的 [PlaylistContentRemoteDataSource] 能力接口。当当前数据源未实现该
/// 能力时返回错误。
class AppPlaylistContentRepository([
  final PlaylistContentRemoteDataSource? _remoteDataSource,
]) implements PlaylistContentRepository {
  @override
  Future<Result<Page<PlaylistDetail>, Exception>> fetchPlaylistContent({
    required String playlistId,
    int page = 1,
    int pageSize = 30,
  }) async {
    if (_remoteDataSource != null) {
      return _remoteDataSource.fetchPlaylistContent(
        playlistId: playlistId,
        page: page,
        pageSize: pageSize,
      );
    }
    return Result.error(
      Exception('Current source does not support playlist content'),
    );
  }

  @override
  Future<FullPlaylistFetchResult<VideoModel>> fetchAll({
    required String playlistId,
    int pageSize = 30,
    int startPage = 1,
    void Function(int fetchedCount)? onProgress,
  }) async {
    final remoteDataSource = _remoteDataSource;
    if (remoteDataSource == null) {
      return FullPlaylistFetchResult<VideoModel>(
        items: const <VideoModel>[],
        completed: false,
        nextPage: startPage,
        error: Exception('Current source does not support playlist content'),
      );
    }

    Future<Page<VideoModel>> loadPage({int? pageKey}) async {
      final result = await remoteDataSource.fetchPlaylistContent(
        playlistId: playlistId,
        page: pageKey ?? 1,
        pageSize: pageSize,
      );
      return switch (result) {
        Success(:final success) => Page<VideoModel>(
          number: success.number,
          totalPages: success.totalPages,
          data: [for (final detail in success.data) ...detail.items],
        ),
        Error(:final error) => throw error,
      };
    }

    final result = await _fetchEveryPage(
      fetchPage: ({int? pageKey}) => loadPage(pageKey: pageKey),
      itemKey: (item) => item.id,
      startPage: startPage,
    );
    onProgress?.call(result.items.length);
    return result;
  }
}

/// 逐页抓取的本地别名。
///
/// 直接写 `fetchFullPlaylist(...)` 会解析到本类新增的成员，故经顶层函数引用。
const _fetchEveryPage = fetchFullPlaylist;
