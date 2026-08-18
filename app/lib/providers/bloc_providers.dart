import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../feature/search/bloc/search_bloc.dart';
import '../feature/search/bloc/search_result_bloc.dart';

List<BlocProvider> get blocProviders => [
  BlocProvider<SearchBloc>(
    create: (context) => .new(
      searchSuggestRepository: context.read(),
      recentSearchQueryRepository: context.read(),
      getRentSearchQueriesUseCase: context.read(),
    ),
  ),
  BlocProvider<SearchResultBloc<VideoInfoBase>>(
    create: (context) => .new(searchContentsRepository: context.read()),
  ),
];
