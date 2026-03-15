import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:logging/logging.dart';

import 'bili_database.dart';
import 'dao/recent_search_query_dao.dart';

final _log = Logger('DatabaseProviders');

List<SingleChildWidget> get databaseProviders =>
  [
    Provider<BiliDatabase>(
      create: (_) => .new(),
      dispose: (_, database) {
        _log.fine('Provider dispose called for BiliDatabase');
        database.close().then((_) {
          _log.fine('BiliDatabase successfully closed.');
        }).catchError((e) {
          _log.warning('Error closing BiliDatabase: $e');
        });
        _log.fine('Provider dispose finished');
      },
    ),
    Provider<recentSearchQueryDao>(
      create: (context) => context.read<BiliDatabase>().recentSearchQueryDao,
    ),
  ];
