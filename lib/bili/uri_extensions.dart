//import 'package:dio/dio.dart';


extension UriExtensions on Uri {
  /*Future<Uri> getFinalUrl() async {
    var finalUri = this;
    final dio = Dio();
    try {
      for (var i = 0; i < 5; i++) {
        final response = await dio.headUri(finalUri);
        if (!response.isRedirect) {
          return finalUri;
        }
        finalUri = response.realUri;
      }
    } catch (e) {
      throw Exception('getFinalUrl $e');
    }
    throw Exception('getFinalUrl ${toString()}: 重定向过多');
  }*/
  
  String get lastSegdment => pathSegments.isNotEmpty ? pathSegments.last : '';
  
  List<String> get hostParts => host.split('.');
  
  String? get secondLevelDomain => hostParts.length >= 2 ? hostParts[0] : null;
  
  bool get isBilibiiScheme => isScheme('bilibili');
  
  bool get isHTTPScheme => isScheme('http') || isScheme('https');
  
}

