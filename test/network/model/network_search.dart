import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'dart:convert';
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

Future<Map<String, dynamic>> getJsonData(String p, String name) {
  final jsonFile = File(path.join(
    Directory.current.path,
    p,
    name,
  ));
  
  final String jsonString = await jsonFile.readAsString();

  return jsonDecode(jsonString);
}