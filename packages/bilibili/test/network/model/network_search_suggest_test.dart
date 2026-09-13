import 'dart:convert';
import 'dart:io';

import 'package:bpi/bpi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  File findFile(String relativePath) {
    var file = File(relativePath);
    if (!file.existsSync()) {
      file = File('packages/bilibili/$relativePath');
    }
    return file;
  }

  group('NetworkSearchSuggest model tests', () {
    test('deserializes search_suggest.json correctly', () {
      final file = findFile(
        'testing/network/fakes/search_suggest/search_suggest.json',
      );
      expect(
        file.existsSync(),
        isTrue,
        reason: 'Search suggest fake file should exist at ${file.path}',
      );
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final suggest = NetworkSearchSuggest.fromJson(json);

      expect(suggest.tag, isNotEmpty);
      expect(suggest.tag.first.term, isNotEmpty);
      expect(suggest.tag.first.name, isNotEmpty);
    });
  });
}
