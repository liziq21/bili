import 'dart:io';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
//import 'package:retrofit/retrofit.dart';

import 'package:f_biuli/bili/constonts/uris.dart';

@module
abstract class NetworkModule {
  @Named('apiBase')
  String get apiBase => ApiUris.base;
  
  @lazySingleton
  Dio get dio => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      headers: {
        HttpHeaders.cookieHeader: '{"SESSDATA"="xxx"}',
      },
    )
  );
}
