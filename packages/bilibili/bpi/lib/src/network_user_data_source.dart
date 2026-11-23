import 'model/user/network_bili_user_article.dart';
import 'model/user/network_bili_user_card.dart';
import 'model/user/network_bili_playlist_content.dart';
import 'model/user/network_bili_user_videos.dart';

abstract class NetworkUserDataSource {
  Future<NetworkBiliUserCardData> getUserCard({required int mid});

  Future<NetworkBiliUserArticlesData> getUserArticles({
    required int mid,
    int page = 1,
    int pageSize = 30,
  });

  Future<NetworkBiliPlaylistContentData> getPlaylistContent({
    required int mid,
    int pageNum = 1,
    int pageSize = 30,
    bool sortReverse = false,
    int? seasonId,
  });

  Future<NetworkBiliUserVideosData> getUserVideos({
    required int mid,
    int page = 1,
    int pageSize = 30,
    String? order,
  });
}

/// 用户合集/系列列表能力。
///
/// 单独成接口，避免给只实现投稿/卡片端点的适配器增加必须实现的方法。
abstract interface class NetworkUserPlaylistDataSource {
  Future<NetworkBiliPlaylistListData> getUserPlaylists({
    required int mid,
    int pageNum = 1,
    int pageSize = 30,
  });
}
