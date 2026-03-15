import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'get_recent_search_queries_use_case.dart';

List<SingleChildWidget> get domainProviders =>
  [
    Provider<GetRecentSearchQueriesUseCase>(
      create: (context) => .new(recentSearchQueryRepository: context.read()),
    ),
  ];
