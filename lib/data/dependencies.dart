import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../bilibili/dependencies.dart';
import '../bilibili/data/repository/bilibili_search_contents_repository.dart';
import '../bilibili/data/repository/bilibili_search_suggest_repository.dart';
import '../database/dependencies.dart';
import '../datastore/dependencies.dart';
import 'model/user_data.dart';
import 'repository/recent_search_query/default_recent_search_query_repository.dart';
import 'repository/recent_search_query/recent_search_query_repository.dart';
import 'repository/search_contents/search_contents_repository.dart';
import 'repository/search_suggest/search_suggest_repository.dart';
import 'repository/user_data/default_user_data_repository.dart';
import 'repository/user_data/user_data_repository.dart';

List<SingleChildWidget> get repositoryProviders => [
  ...databaseProviders,
  ...datastoreProviders,
  ...bilibiliProviders,

  Provider<UserDataRepository>(
    create: (context) =>
        DefaultUserDataRepository(preferencesDataSource: context.read()),
  ),
  Provider<RecentSearchQueryRepository>(
    create: (context) => DefaultRecentSearchQueryRepository(
      recentSearchQueryDao: context.read(),
    ),
  ),

  // https://github.com/rrousselGit/provider/blob/master/packages/provider/lib/src/async_provider.dart
  StreamProvider<ServiceSource>(
    create: (context) => context
        .read<UserDataRepository>()
        .data
        .map<ServiceSource>((userData) => userData.serviceSource),
    initialData: .bilibili,
  ),

  ProxyProvider<ServiceSource, SearchContentsRepository?>(
    update: (context, serviceSource, _) {
      return switch (serviceSource) {
        .bilibili => BilibiliSearchContentsRepository(network: context.read()),
        .youtube => null,
      };
    },
  ),
  ProxyProvider<ServiceSource, SearchSuggestRepository?>(
    update: (context, serviceSource, _) {
      return switch (serviceSource) {
        .bilibili => BilibiliSearchSuggestRepository(network: context.read()),
        .youtube => null,
      };
    },
  ),
];
