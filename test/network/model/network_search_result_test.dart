import 'package:flutter_test/flutter_test.dart';
import 'package:f_biuli/network/retrofit/api_result.dart';
import 'package:f_biuli/network/model/search/network_search_result.dart';
import '../../../testing/network/retrofit/api_result.dart';

void main() {
  
  Future<NetworkSearchResult> _loadAndDeserialize(String fileName) async {
    final result = await ApiResultUtils.fromFile<NetworkSearchResult>(
      fileDir: 'testing/network/fakes/search',
      fileName: fileName,
      fromJsonT: NetworkSearchResult.fromJson,
    );
    return result.asOk.data;
  }

  group('NetworkSearchResult Deserialization', () {
    test('should deserialize search.json correctly', () async {
      final data = await _loadAndDeserialize('search.json');
      print('$data');
      expect(data.result.video[0].typename, '数码');
    });

    test('should deserialize type_search.json correctly', () async {
      final data = await _loadAndDeserialize('type_search.json');
      print('$data');
      expect(data.result.article[0].like, 24);
    });

    test('should deserialize live_search.json correctly', () async {
      final data = await _loadAndDeserialize('live_search.json');
      print('$data');
      expect(data.result.liveRoom[0].area, 3);
    });
  });
}
