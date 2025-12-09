import 'package:flutter_test/flutter_test.dart';
import 'package:f_biuli/network/retrofit/api_result.dart';
import 'package:f_biuli/network/model/search_suggest/network_search_suggest.dart';
import '../../../testing/network/retrofit/api_result.dart';

void main() {
  Future<NetworkSearchSuggest> _loadAndDeserialize(String fileName) async {
    final result = await ApiResultUtils.fromFile<NetworkSearchSuggest>(
      fileDir: 'testing/network/fakes/search_suggest',
      fileName: fileName,
      fromJsonT: NetworkSearchSuggest.fromJson,
    );
    return result.asOk.data;
  }

  group('NetworkSearchSuggest Deserialization', () {
    test('should deserialize search_suggest.json correctly', () async {
      final data = await _loadAndDeserialize('search_suggest.json');
      print('$data');
      expect(data.tag[0].term, 'freepalestine');
    });
  });
}
