import 'package:flutter_bloc/flutter_bloc.dart';

import '../app_bloc.dart';
import '../feature/search/bloc/search_bloc.dart';

List<BlocProvider> get blocProviders => [
  BlocProvider<AppBloc>(
    create: ((context) {
      return .new(userDataRepository: context.read());
    }),
  ),
  BlocProvider<SearchBloc>(
    create: (context) => .new(
      searchSuggestRepository: context.read(),
      recentSearchQueryRepository: context.read(),
      getRentSearchQueriesUseCase: context.read(),
    ),
  ),
];
