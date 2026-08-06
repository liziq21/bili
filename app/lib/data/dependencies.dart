import 'package:data/data.dart';
import 'package:database/database.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'repository/recent_search_query/default_recent_search_query_repository.dart';
import 'repository/user_data/default_user_data_repository.dart';

final _log = Logger('DatabaseProviders');

List<SingleChildWidget> get databaseProviders => [
  Provider<BiliDatabase>(
    create: (_) => .new(),
    dispose: (_, database) {
      _log.fine('Provider dispose called for BiliDatabase');
      database
          .close()
          .then((_) {
            _log.fine('BiliDatabase successfully closed.');
          })
          .catchError((e) {
            _log.warning('Error closing BiliDatabase: $e');
          });
      _log.fine('Provider dispose finished');
    },
  ),
  Provider<RecentSearchQueryDao>(
    create: (context) => context.read<BiliDatabase>().recentSearchQueryDao,
  ),
];

List<SingleChildWidget> get repositoryProviders => [
  ...databaseProviders,
  Provider<VideoSearchRepository?>(create: (context) => context.read()),
  Provider<UserDataRepository>(
    create: (context) =>
        DefaultUserDataRepository(preferencesDataSource: .new()),
  ),
  Provider<RecentSearchQueryRepository>(
    create: (context) => DefaultRecentSearchQueryRepository(
      recentSearchQueryDao: context.read(),
    ),
  ),

  // https://github.com/rrousselGit/provider/blob/master/packages/provider/lib/src/async_provider.dart
  /*StreamProvider<ServiceSource>(
    create: (context) => context
        .read<UserDataRepository>()
        .data
        .map<ServiceSource>((userData) => userData.serviceSource),
    initialData: .bilibili,
  ),

  ProxyProvider<ServiceSource, SearchContentsRepository?>(
    update: (context, serviceSource, _) {
      return switch (serviceSource) {
        .bilibili => BilibiliVideoSearchRepository(network: context.read()),
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
  ),*/
];
