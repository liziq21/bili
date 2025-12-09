import 'package:flutter_test/flutter_test.dart';
import 'package:f_biuli/network/retrofit/api_result.dart';
import 'package:f_biuli/network/model/search_suggest/network_search_suggest.dart';
import '../../../testing/network/retrofit/api_result.dart';

void main() {
  Future<ApiResult> _loadAndDeserialize(String fileName) async {
    return ApiResult.fromFile(
      fileDir: 'testing/network/fakes/search_suggest',
      fileName: fileName,
      fromJsonT: NorworkSearchSuggest.fromJson,
    );
  }

  group('NetworkSearchSuggest Deserialization', () {
    test('should deserialize search_suggest.json correctly', () async {
      final apiResult = await _loadAndDeserialize('search_suggest.json')
      print('apiResult');
      expect(apiResult.Ok.result.tag[0].term, 'freepalestine');
    });
  });
}
