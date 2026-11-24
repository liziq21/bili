import '../network_feed_data_source.dart';
import '../network_live_data_source.dart';
import '../network_search_data_source.dart';
import '../network_user_data_source.dart';
import '../network_video_data_source.dart';
import 'bili_network_client.dart';
import 'feed_endpoints.dart';
import 'live_endpoints.dart';
import 'search_endpoints.dart';
import 'user_endpoints.dart';
import 'video_endpoints.dart';

/// Bilibili's public Web API client.
///
/// Each mixin owns one data-source domain; this class only assembles them.
final class BiliNetworkSearch extends BiliNetworkClient
    with
        SearchEndpoints,
        VideoEndpoints,
        LiveEndpoints,
        FeedEndpoints,
        UserEndpoints
    implements
        NetworkSearchDataSource,
        NetworkVideoDataSource,
        NetworkBiliFeedDataSource,
        NetworkLiveDataSource,
        NetworkUserDataSource,
        NetworkUserPlaylistDataSource {
  BiliNetworkSearch({super.client, super.storage});
}
