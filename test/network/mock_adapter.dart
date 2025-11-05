import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import 'package:f_biuli/bili/constonts/uris.dart';

class MockAdapter extends IOHttpClientAdapter {
  static const String mockHost = 'mockserver';
  static const String mockBase = 'http://$mockHost';
  final _adapter = IOHttpClientAdapter();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async {
    final uri = options.uri;
    switch(uri.host) {
      case ApiUris.host:
      case SearchUris.host:
      default: ResponseBody.fromString('', 404);
    }
    
    
    /*if (uri.host == Api.host) {
      switch (uri.path) {
        case '/tags':
          return ResponseBody.fromString(
            jsonEncode(['tag1', 'tag2']),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        default:
          return ResponseBody.fromString('', 404);
      }
    }*/
    return _adapter.fetch(options, requestStream, cancelFuture);
  }

  @override
  void close({bool force = false}) {
    _adapter.close(force: force);
  }
}