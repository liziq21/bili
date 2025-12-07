import 'package:dio/dio.dart';
import 'package:flutter_debug_overlay/flutter_debug_overlay.dart';


class DioDi {
  final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        headers: {
          HttpHeaders.cookieHeader: '{"SESSDATA"="xxx"}',
        },
      ),
    )..interceptors.add(DioLogInterceptor(App.httpBucket)),
}