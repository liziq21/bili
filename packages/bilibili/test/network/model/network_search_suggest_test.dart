import 'dart:convert';
import 'dart:io';

import 'package:bpi/bpi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  File findFile(String key) {
    final candidatePaths = [
      'packages/bilibili/bpi/testing/$key.json',
      'bpi/testing/$key.json',
      'testing/$key.json',
    ];
    for (final path in candidatePaths) {
      final file = File(path);
      if (file.existsSync()) return file;
    }
    return File(candidatePaths.first);
  }

  Map<String, dynamic> loadFake(String key) {
    final file = findFile(key);
    expect(
      file.existsSync(),
      isTrue,
      reason: 'Search suggest fake file should exist at ${file.path}',
    );
    final content = file.readAsStringSync();
    return jsonDecode(content) as Map<String, dynamic>;
  }

  group('NetworkSearchSuggest model tests', () {
    test('deserializes search_suggest.json correctly', () {
      final json = loadFake('search_suggest');
      final data = (json['data'] ?? json) as Map<String, dynamic>;
      final result = NetworkSearchSuggest.fromJson(data);

      expect(result.tag, isNotEmpty);
    });
  });
}
