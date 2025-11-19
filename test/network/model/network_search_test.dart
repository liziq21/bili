import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

import 'package:f_biuli/network/model/search/network_search.dart';

import '../../../testing/network/model/network_search.dart';

void main() {
  group('User Deserialization Test', () {
    test('should deserialize a list of NetworkSearch objects from JSON file', () async {
      final search = await getJsonData('testing/network/fakes', 'search.json');
      expect(NetworkSearch.fromJson(search), networkSearch);
      
      final typeSearch = await getJsonData('testing/network/fakes', 'type_search.json');
      expect(NetworkSearch.fromJson(typeSearch), networkTypeSearch);
      
      final liveSearch = await getJsonData('testing/network/fakes', 'live_search.json');
      expect(NetworkSearch.fromJson(liveSearch), networkLiveSearch);
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