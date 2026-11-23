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

  test('descriptor provenance fingerprints match the fixtures', () {
    for (final entry in [
      (biliPopularFeedDescriptor, 'bpi/testing/popular.json'),
      (biliRankingFeedDescriptor, 'bpi/testing/ranking.json'),
      (biliUserVideosDescriptor, 'bpi/testing/space_videos.json'),
    ]) {
      final provenance = entry.$1.provenance;
      expect(provenance, isNotNull, reason: entry.$2);
      final fixture = jsonDecode(File(entry.$2).readAsStringSync()) as Object?;
      final fingerprint = fingerprintJson(fixture);
      expect(
        provenance!.fixtureHash,
        fingerprint.fixtureHash,
        reason: 'fixture drift: ${entry.$2}',
      );
      expect(
        provenance.sourceSchemaHash,
        fingerprint.sourceSchemaHash,
        reason: 'source schema drift: ${entry.$2}',
      );
    }
  });

  test('popular feed exposes exact task-level values', () async {
    final page = await _fetchPage(
      'popular',
      _readJson('bpi/testing/popular.json') as Map<String, dynamic>,
    );

    expect(page.number, 1);
    expect(page.totalPages, 2);
    expect(page.data, hasLength(20));
    expect(page.data.map((video) => video.id).toSet(), hasLength(20));
    final first = page.data.first;
    expect(first.id, 'BV1Deht6rEpZ');
    expect(first.title, '我记录下了妹妹的最后7天...【自制伪纪录片电影】');
    expect(first.url, 'https://www.bilibili.com/video/BV1Deht6rEpZ');
    expect(
      first.thumbnailUrl,
      'https://i0.hdslb.com/bfs/archive/'
      '25532448b0bef5b5a71b1515bb4264da3f6b5890.jpg',
    );
    expect(first.viewCount, 2710290);
    expect(first.uploadDate?.millisecondsSinceEpoch, 1790242200000);
    expect(first.duration, 399);
    expect(first.creatorProfileName, '沢人');
    expect(first.creatorProfileId, '2057895471');
  });

  test('ranking feed exposes exact task-level values', () async {
    final page = await _fetchPage(
      'ranking',
      _readJson('bpi/testing/ranking.json') as Map<String, dynamic>,
    );

    expect(page.number, 1);
    expect(page.totalPages, 1);
    expect(page.data, hasLength(100));
    expect(page.data.map((video) => video.id).toSet(), hasLength(100));
    final first = page.data.first;
    expect(first.id, 'BV1YDhJ6ZEL6');
    expect(first.title, '《柯洁围棋入门课》');
    expect(first.url, 'https://www.bilibili.com/video/BV1YDhJ6ZEL6');
    expect(first.viewCount, 4141862);
    expect(first.uploadDate?.millisecondsSinceEpoch, 1790069133000);
    expect(first.duration, 499);
    expect(first.creatorProfileName, '柯洁');
    expect(first.creatorProfileId, '525952604');
  });

  test('declarative descriptors satisfy the canonical video contract', () {
    for (final descriptor in [
      biliPopularFeedDescriptor,
      biliRankingFeedDescriptor,
      biliUserVideosDescriptor,
    ]) {
      expect(
        validateFeedMappingDescriptor(
          descriptor,
          requiredFields: VideoModel.requiredFields,
          requireProvenance: true,
          requireFingerprint: true,
        ),
        isEmpty,
      );
    }
  });
}

Future<Page<VideoModel>> _fetchPage(
  String feed,
  Map<String, dynamic> fixture,
) async {
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
  return switch (result) {
    Success(:final success) => success,
    Error(:final error) => fail('expected success: $error'),
  };
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
