import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'network_search_data_source.dart';
import 'retrofit/retrofit_network.dart';

List<SingleChildWidget> get networkProviders =>
  [
    Provider(create: (context) {
      late final Dio dio;
      try {
        dio = context.read()
          ..options.headers[HttpHeaders.cookieHeader] = 'SESSDATA=xxx';
      } catch (_) {
        dio = Dio(BaseOptions(headers: {
          HttpHeaders.cookieHeader: 'SESSDATA=xxx',
        }));
      }
      return BiliNetworkSearch(dio: dio) as NetworkSearchDataSource;
    }),
  ];
