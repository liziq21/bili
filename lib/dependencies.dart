import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'app.dart';
import 'data/repository/recent_search_query/default_recent_search_query_repository.dart';
import 'data/repository/recent_search_query/recent_search_query_repository.dart';
import 'data/repository/search_contents/bili_search_contents_repository.dart';
import 'data/repository/search_contents/search_contents_repository.dart';
import 'data/repository/search_suggest/bili_search_suggest_repository.dart';
import 'data/repository/search_suggest/search_suggest_repository.dart';
import 'data/repository/user_data/default_user_data_repository.dart';
import 'data/repository/user_data/user_data_repository.dart';
import 'database/dao/recent_search_query_dao.dart';
import 'datastore/preferences_data_source.dart';
import 'network/network_search_data_source.dart';
import 'network/retrofit/retrofit_network.dart';

/// Shared providers for all configurations.
List<SingleChildWidget> _sharedProviders = [
  /*Provider(
    lazy: true,
    create: (context) => BookingCreateUseCase(
      bookingRepository: context.read(),
    ),
  ),
  Provider(
    lazy: true,
    create: (context) => BookingShareUseCase.withSharePlus(),
  ),*/
];

List<SingleChildWidget> get providers {
  return [
    Provider(create: (context) => PreferencesDataSource()), 
    Provider(create: (context) =>
      Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      )..interceptors.add(DioLogInterceptor(App.httpBucket)),
    ),
    Provider(create: (context) => 
      BiliNetworkSearch(
        dio: context.read(),
      ) as NetworkSearchDataSource,
    ),
    Provider(create: (context) =>
      DefaultUserDataRepository(
        preferencesDataSource: context.read(),
      ) as UserDataRepository
    ),
    Provider(create: (context) =>
      DefaultRecentSearchQueryRepository(
        preferencesDataSource: context.read(),
      ) as RecentSearchQueryRepository
    ),
    Provider(create: (context) => 
      BiliSearchContentsRepository(
        networkApi: context.read(),
      ) as SearchContentsRepository,
    ),
    Provider(create: (context) => 
      BiliSearchSuggestRepository(
        networkApi: context.read(),
      ) as SearchSuggestRepository,
    ),
/*
    Provider(
      create: (context) =>
          DestinationRepositoryRemote(apiClient: context.read())
              as DestinationRepository,
    ),
    Provider.value(
      value: ItineraryConfigRepositoryMemory() as ItineraryConfigRepository,
    ),
    Provider(
      create: (context) =>
          BookingRepositoryRemote(apiClient: context.read())
              as BookingRepository,
    ),
    Provider(
      create: (context) =>
          UserRepositoryRemote(apiClient: context.read()) as UserRepository,
    ),*/
    ..._sharedProviders,
  ];
}
