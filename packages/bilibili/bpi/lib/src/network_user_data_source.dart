import 'model/user/network_bili_user_article.dart';
import 'model/user/network_bili_user_card.dart';
import 'model/user/network_bili_user_videos.dart';

abstract class NetworkUserDataSource {
  Future<NetworkBiliUserCardData> getUserCard({required int mid});

  Future<NetworkBiliUserArticlesData> getUserArticles({
    required int mid,
    int page = 1,
    int pageSize = 30,
  });

  Future<NetworkBiliUserVideosData> getUserVideos({
    required int mid,
    int page = 1,
    int pageSize = 30,
    String? order,
  });
}
