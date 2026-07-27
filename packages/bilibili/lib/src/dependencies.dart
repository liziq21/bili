import 'package:bpi/bpi.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:data/data.dart';
import 'data/repository/bilibili_search_contents_repository.dart';
import 'data/repository/bilibili_search_suggest_repository.dart';

List<SingleChildWidget> get bilibiliProviders => [
  Provider<NetworkSearchDataSource>(create: (_) => BiliNetworkSearch()),
  Provider<VideoSearchRepository>(
    create: (context) => BilibiliVideoSearchRepository(network: context.read()),
  ),
  Provider<CreatorProfileSearchRepository>(
    create: (context) => BilibiliUserSearchRepository(network: context.read()),
  ),
  Provider<LiveRoomSearchRepository>(
    create: (context) =>
        BilibiliLiveRoomSearchRepository(network: context.read()),
  ),
  Provider<AggregateSearchRepository>(
    create: (context) =>
        BilibiliAggregateSearchRepository(network: context.read()),
  ),
  Provider<SearchSuggestRepository>(
    create: (context) =>
        BilibiliSearchSuggestRepository(network: context.read()),
  ),
];
