import '../model/user/network_bili_playlist_content.dart';
import '../model/user/network_bili_series_archives.dart';
import '../model/user/network_bili_user_article.dart';
import '../model/user/network_bili_user_card.dart';
import '../model/user/network_bili_user_videos.dart';
import '../network_user_data_source.dart';
import 'bili_network_client.dart';

mixin UserEndpoints on BiliNetworkClient
    implements NetworkUserDataSource, NetworkUserPlaylistDataSource {
  @override
  Future<NetworkBiliSeriesArchives> getSeriesArchives({
    required int mid,
    required int seriesId,
    int page = 1,
    int pageSize = 30,
  }) => api.getSeriesArchives(
    mid: mid,
    seriesId: seriesId,
    page: page,
    pageSize: pageSize,
  );

  @override
  Future<NetworkBiliUserCardData> getUserCard({required int mid}) =>
      api.getUserCard(mid: mid);

  @override
  Future<NetworkBiliUserArticlesData> getUserArticles({
    required int mid,
    int page = 1,
    int pageSize = 30,
  }) => api.getUserArticles(mid: mid, page: page, pageSize: pageSize);

  @override
  Future<NetworkBiliUserVideosData> getUserVideos({
    required int mid,
    int page = 1,
    int pageSize = 30,
    String? order,
  }) =>
      api.getUserVideos(mid: mid, page: page, pageSize: pageSize, order: order);

  @override
  Future<NetworkBiliPlaylistContentData> getPlaylistContent({
    required int mid,
    int pageNum = 1,
    int pageSize = 30,
    bool sortReverse = false,
    int? seasonId,
  }) => api.getPlaylistContent(
    mid: mid,
    pageNum: pageNum,
    pageSize: pageSize,
    sortReverse: sortReverse,
    seasonId: seasonId,
  );

  @override
  Future<NetworkBiliPlaylistListData> getUserPlaylists({
    required int mid,
    int pageNum = 1,
    int pageSize = 30,
  }) => api.getUserPlaylists(mid: mid, pageNum: pageNum, pageSize: pageSize);
}
