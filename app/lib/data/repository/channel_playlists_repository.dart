import 'package:data/data.dart';
import 'package:model/model.dart';

/// 频道页合集分页能力。
///
/// 与 [ChannelVideosRepository] 一样按当前频道直接翻页，不写本地库。
/// 列表项只带合集头，点开后由播放列表页拉取条目。
abstract interface class ChannelPlaylistsRepository() {
  Future<Result<Page<PlaylistDetail>, Exception>> fetchPlaylists({
    required String channelId,
    int page = 1,
    int pageSize = 30,
  });
}

final class AppChannelPlaylistsRepository(
  final ChannelPlaylistsRemoteDataSource _remote,
) implements ChannelPlaylistsRepository {
  @override
  Future<Result<Page<PlaylistDetail>, Exception>> fetchPlaylists({
    required String channelId,
    int page = 1,
    int pageSize = 30,
  }) => _remote.fetchChannelPlaylists(
    channelId: channelId,
    page: page,
    pageSize: pageSize,
  );
}
