import 'package:dio/dio.dart';
import 'package:flutter_debug_overlay/flutter_debug_overlay.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'app.dart';
import 'data/dependencies.dart';
import 'domain/dependencies.dart';

List<SingleChildWidget> get providers =>
  [
    ...repositoryProviders,
    ...domainProviders,
    Provider(create: (context) => 
      Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      )..interceptors.add(DioLogInterceptor(App.httpBucket)),
    ),
  ];
