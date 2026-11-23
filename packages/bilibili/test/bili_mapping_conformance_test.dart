import 'dart:convert';
import 'dart:io';

import 'package:bilibili/bilibili.dart';
import 'package:bilibili/src/data/source/declarative/bili_feed_conformance.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:model/model.dart';

void main() {
  test('popular fixture conforms to the legacy-adapter golden', () async {
    await _expectConforms(
      feed: 'popular',
      fixturePath: 'bpi/testing/popular.json',
      goldenPath: 'test/fixtures/declarative/popular.json',
    );
  });

  test('ranking fixture conforms to the legacy-adapter golden', () async {
    await _expectConforms(
      feed: 'ranking',
      fixturePath: 'bpi/testing/ranking.json',
      goldenPath: 'test/fixtures/declarative/ranking.json',
    );
  });

  test('declarative feeds target the canonical video schema version', () {
    expect(biliPopularFeedDescriptor.schemaVersion, VideoModel.schemaVersion);
    expect(biliRankingFeedDescriptor.schemaVersion, VideoModel.schemaVersion);
  });
}

Future<void> _expectConforms({
  required String feed,
  required String fixturePath,
  required String goldenPath,
}) async {
  final fixture = _readJson(fixturePath) as Map<String, dynamic>;
  final source = switch (feed) {
    'popular' => createBiliPopularDeclarativeFeed(
      fetchJson: ({int? pageKey}) async => fixture,
    ),
    'ranking' => createBiliRankingDeclarativeFeed(
      fetchJson: ({int? pageKey}) async => fixture,
    ),
    _ => throw ArgumentError.value(feed, 'feed'),
  };

  final result = await source.fetchFeed();
  final page = switch (result) {
    Success(:final success) => success,
    Error(:final error) => fail('expected success: $error'),
  };
  final actual = [for (final video in page.data) canonicalVideoJson(video)];
  final expected = _readJson(goldenPath);
  final differences = diffJson(expected, actual);

  expect(
    differences,
    isEmpty,
    reason: differences
        .take(10)
        .map(
          (difference) =>
              '${difference.path}: expected ${difference.expected}, '
              'actual ${difference.actual}',
        )
        .join('\n'),
  );
}

Object? _readJson(String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: 'missing fixture: $path');
  return jsonDecode(file.readAsStringSync());
}
