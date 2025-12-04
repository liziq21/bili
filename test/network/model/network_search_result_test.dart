import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:f_biuli/network/retrofit/api_result.dart';
import 'package:f_biuli/network/model/search/network_search_result.dart';
//import '../../../testing/utils/result.dart';

void main() {
  const String jsonDir = 'testing/network/fakes';

  Future<NetworkSearchResult> _loadAndDeserialize(String fileName) async {
    final json = await getJsonData(jsonDir, fileName);
    final apiResult = ApiResult.fromJson(
      json,
      NetworkSearchResult.fromJson,
    );
    return (apiResult as ApiResultOk).data;
  }

  group('NetworkSearchResult Deserialization', () {
    test('should deserialize search.json correctly', () async {
      final searchResult = await _loadAndDeserialize('search.json');
      expect(searchResult.result.video[0].typename, '数码');
    });

    test('should deserialize type_search.json correctly', () async {
      final typeSearchResult = await _loadAndDeserialize('type_search.json');
      expect(typeSearchResult.result.article[0].like, 24);
    });

    test('should deserialize live_search.json correctly', () async {
      final liveSearchResult = await _loadAndDeserialize('live_search.json');
      expect(liveSearchResult.result.liveRoom[0].area, 3);
    });
  });
}

Future<Map<String, dynamic>> getJsonData(String dirPath, String fileName) async {
  final String fullPath = path.join(
    Directory.current.path,
    dirPath,
    fileName,
  );

  final File jsonFile = File(fullPath);

  try {
    if (!await jsonFile.exists()) {
      throw FileSystemException('File not found', fullPath);
    }

    final String jsonString = await jsonFile.readAsString();
    final Map<String, dynamic> jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

    return jsonData;
  } on PathNotFoundException {
    throw Exception('JSON file not found at: $fullPath');
  } on FileSystemException catch (e) {
    throw Exception('Failed to read JSON file at $fullPath: ${e.message}');
  } on FormatException catch (e) {
    throw Exception('Invalid JSON format in file $fullPath: ${e.message}');
  } on TypeError catch (e) {
    throw Exception('JSON root is not a Map<String, dynamic> in file $fullPath: ${e.toString()}');
  } catch (e) {
    throw Exception('An unexpected error occurred while loading JSON from $fullPath: $e');
  }
}