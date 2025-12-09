import 'package:flutter_test/flutter_test.dart';
import 'package:f_biuli/network/retrofit/api_result.dart';
import 'package:f_biuli/network/model/search/network_search_result.dart';
import '../../../testing/network/retrofit/api_result.dart';

void main() {
  
  Future<ApiResult<NorworkSearchResult>> _loadAndDeserialize(String fileName) async {
    return ApiResult<NorworkSearchResult>.fromFile(
      fileDir: 'testing/network/fakes/search',
      fileName: fileName,
      fromJsonT: NetworkSearchResult.fromJson,
    );
  }

  group('NetworkSearchResult Deserialization', () {
    test('should deserialize search.json correctly', () async {
      final apiResult = await _loadAndDeserialize('search.json');
      print('apiResult');
      expect(apiResult.asOk.result.video[0].typename, '数码');
    });

    test('should deserialize type_search.json correctly', () async {
      final apiResult = await _loadAndDeserialize('type_search.json');
      print('apiResult');
      expect(apiResult.asOk.result.article[0].like, 24);
    });

    test('should deserialize live_search.json correctly', () async {
      final apiResult = await _loadAndDeserialize('live_search.json');
      print('apiResult');
      expect(apiResult.asOk.result.liveRoom[0].area, 3);
    });
  });
}
