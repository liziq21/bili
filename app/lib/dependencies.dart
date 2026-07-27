// import 'package:flutter_debug_overlay/flutter_debug_overlay.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'app_view_model.dart';
import 'data/dependencies.dart';
import 'package:domain/domain.dart';

List<SingleChildWidget> get providers => [
  ...repositoryProviders,
  //...domainProviders,
  Provider<AppViewModel>(
    create: (context) => .new(userDataRepository: context.read()),
  ),
  Provider<GetRecentSearchQueriesUseCase>(
    create: (context) => .new(recentSearchQueryRepository: context.read()),
  ),
  /*Provider(create: (context) =>
      Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      )..interceptors.add(DioLogInterceptor(App.httpBucket)),
    ),*/
];
