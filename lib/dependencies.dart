import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'app.dart'
import 'data/repository/search_contents/bili_search_contents_repository.dart';
import 'data/repository/search_contents/search_contents_repository.dart';
import 'data/repository/search_suggest/bili_search_suggest_repository.dart';
import 'data/repository/search_suggest/search_suggest_repository.dart';
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
      BiliSearchContentsRepository(
        networkApi: context.read(),
      ) as SearchContentsRepository,
    ),
    Provider(create: (context) => 
      BiliSearchSuggestRepository(
        networkApi: context.read(),
      ) as SearchSuggestRepository,
    ),
    /*ChangeNotifierProvider(
      create: (context) =>
          AuthRepositoryRemote(
                authApiClient: context.read(),
                apiClient: context.read(),
                sharedPreferencesService: context.read(),
              )
              as AuthRepository,
    ),
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
