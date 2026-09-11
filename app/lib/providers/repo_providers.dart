import 'package:bilibili/bilibili.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repository/recent_search_query/default_recent_search_query_repository.dart';
import '../../data/repository/recent_search_query/recent_search_query_repository.dart';
import '../../data/repository/search/app_live_room_search_repository.dart';
import '../../data/repository/search/app_user_search_repository.dart';
import '../../data/repository/search/app_video_search_repository.dart';
import '../../data/repository/search_contents_repository.dart';
import '../../data/repository/search_suggest_repository.dart';
import '../../data/repository/user_data/default_user_data_repository.dart';
import '../../data/repository/user_data/user_data_repository.dart';
import '../../database/app_database.dart';
import '../../database/dao/recent_search_query_dao.dart';
import '../../datastore/preferences_data_source.dart';

import 'package:logging/logging.dart';

import '../../domain/get_recent_search_queries_use_case.dart';

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
    create: (_) => .new(),
    dispose: (pref) => pref.dispose(),
  ),
];

List<RepositoryProvider> get repoProviders => [
  ...databaseProviders,
  ...preferencesProviders,
  RepositoryProvider<UserDataRepository>(
    create: ((context) =>
        DefaultUserDataRepository(preferencesDataSource: context.read())),
  ),
  RepositoryProvider<RecentSearchQueryRepository>(
    create: ((context) => DefaultRecentSearchQueryRepository(
      recentSearchQueryDao: context.read(),
    )),
  ),
  RepositoryProvider<GetRecentSearchQueriesUseCase>(
    create: (context) => .new(recentSearchQueryRepository: context.read()),
  ),
  RepositoryProvider<Bili>(
    create: (_) => .new(),
    dispose: (bili) => bili.close(),
  ),
  RepositoryProvider<VideoSearchRepository>(
    create: (context) => AppVideoSearchRepository(
      context.read<Bili>().videoSearchDataSource(),
    ),
  ),
  RepositoryProvider<CreatorProfileSearchRepository>(
    create: (context) => AppUserSearchRepository(
      context.read<Bili>().creatorProfileSearchDataSource(),
      context.read<Bili>().searchSuggestDataSource(),
    ),
  ),
  RepositoryProvider<LiveRoomSearchRepository>(
    create: (context) => AppLiveRoomSearchRepository(
      context.read<Bili>().liveRoomSearchDataSource(),
    ),
  ),
  RepositoryProvider<SearchSuggestRepository>(
    create: (context) => AppUserSearchRepository(
      context.read<Bili>().creatorProfileSearchDataSource(),
      context.read<Bili>().searchSuggestDataSource(),
    ),
  ),
];
