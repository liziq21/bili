import 'package:bilibili/bilibili.dart';
import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../database/app_database.dart';
import '../database/dao/recent_search_query_dao.dart';
import '../datastore/preferences_data_source.dart';

import 'package:logging/logging.dart';

final _log = Logger('DatabaseProviders');

List<RepositoryProvider> get databaseProviders => [
  RepositoryProvider<AppDatabase>(
    create: (_) => .new(),
    dispose: (database) {
      _log.fine('Provider dispose called for BiliDatabase');
      database
          .close()
          .then((_) {
            _log.fine('AppDatabase successfully closed.');
          })
          .catchError((e) {
            _log.warning('Error closing BiliDatabase: $e');
          });
      _log.fine('Provider dispose finished');
    },
  ),
  RepositoryProvider<RecentSearchQueryDao>(
    create: (context) => context.read<AppDatabase>().recentSearchQueryDao,
  ),
];

List<RepositoryProvider> get preferencesProviders => [
  RepositoryProvider<PreferencesDataSource>(
    create: (context) => .new(),
    dispose: (pref) => pref.dispose(),
  ),
];

List<RepositoryProvider> get repoProviders => [
  RepositoryProvider<Bili>(create: (_) => .new()),
  RepositoryProvider<VideoSearchRepository>(
    create: (context) => context.read<Bili>().videoSearchRepository(),
  ),
  RepositoryProvider<CreatorProfileSearchRepository>(
    create: (context) => context.read<Bili>().userSearchRepository(),
  ),
  RepositoryProvider<LiveRoomSearchRepository>(
    create: (context) => context.read<Bili>().liveRoomSearchRepository(),
  ),
  RepositoryProvider<AggregateSearchRepository>(
    create: (context) => context.read<Bili>().aggregateSearchRepository(),
  ),
  RepositoryProvider<SearchSuggestRepository>(
    create: (context) => context.read<Bili>().searchSuggestRepository(),
  ),
];
