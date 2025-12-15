import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'repository/recent_search_query/default_recent_search_query_repository.dart';
import 'repository/recent_search_query/recent_search_query_repository.dart';
import 'repository/search_contents/bili_search_contents_repository.dart';
import 'repository/search_contents/search_contents_repository.dart';
import 'repository/search_suggest/bili_search_suggest_repository.dart';
import 'repository/search_suggest/search_suggest_repository.dart';
import 'repository/user_default_user_data_repository.dart';
import 'repository/user_user_data_repository.dart';
import 'database/dependencies.dart';
import 'datastore/dependencies.dart';
import 'network/dependencies.dart';

List<SingleChildWidget> get repositoryProviders =>
  [
    ...databaseProviders, 
    ...datastoreProviders, 
    ...networkProviders,
    Provider(create: (context) =>
      DefaultUserDataRepository(
        preferencesDataSource: context.read(),
      ) as UserDataRepository,
    ),
    Provider(create: (context) =>
      DefaultRecentSearchQueryRepository(
        recentSearchQueryDao: context.read(),
      ) as RecentSearchQueryRepository,
    ),
    Provider(create: (context) => 
      BiliSearchContentsRepository(
        network: context.read(),
      ) as SearchContentsRepository,
    ),
    Provider(create: (context) => 
      BiliSearchSuggestRepository(
        network: context.read(),
      ) as SearchSuggestRepository,
    ),
  ];
