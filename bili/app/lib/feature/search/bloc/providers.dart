import 'package:data/data.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'search_bloc.dart';
import 'search_result_bloc.dart';

List<BlocProvider> getSearchBlocProviders(BuildContext context) => [
  BlocProvider<SearchBloc>(
    create: (context) => .new(
      searchSuggestRepository: context.read(),
      recentSearchQueryRepository: context.read(),
      getRentSearchQueriesUseCase: context.read(),
    ),
  ),
  if (context.read<VideoSearchRepository?>()
      case final VideoSearchRepository searchContentsRepo)
    BlocProvider<SearchResultBloc<VideoInfoBase>>(
      create: (context) => .new(searchContentsRepository: searchContentsRepo),
    ),

  if (context.read<CreatorProfileSearchRepository?>()
      case final CreatorProfileSearchRepository searchContentsRepo)
    BlocProvider<SearchResultBloc<CreatorProfile>>(
      create: (context) => .new(searchContentsRepository: searchContentsRepo),
    ),
];
