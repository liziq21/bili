import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'bili_database.dart';
import 'dao/recent_search_query_dao.dart';

List<SingleChildWidget> get databaseProviders =>
  [
    Provider(create: (context) => BiliDatabase()),
    Provider(create: (context) => RecentSearchQueryDao(context.read())),
  ];
