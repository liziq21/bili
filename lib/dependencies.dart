import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'data/repository/search/bili_search_repository.dart';
import 'data/repository/search/search_suggest_repository.dart';
import 'data/repository/search/bili_search_suggest_repository.dart';
import 'data/repository/search/search_repository.dart';
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
    Provider(create: (context) => BiliNetworkSearch() as NetworkSearchDataSource),
    Provider(create: (context) => 
      BiliSearchRepository(
        networkApi: context.read(),
      ) as SearchRepository,
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
