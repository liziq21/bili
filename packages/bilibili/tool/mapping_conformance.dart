import 'dart:convert';
import 'dart:io';

import 'package:bilibili/src/data/source/bili_popular_video_feed_remote_data_source.dart';
import 'package:bilibili/src/data/source/bili_ranking_video_feed_remote_data_source.dart';
import 'package:bilibili/src/data/source/declarative/bili_feed_conformance.dart';
import 'package:bilibili/src/data/source/declarative/bili_feed_descriptors.dart';
import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:model/model.dart';

/// Compares a declarative Bilibili feed against a committed canonical golden.
///
/// Run from `packages/bilibili`:
///
/// ```text
/// dart run tool/mapping_conformance.dart --feed popular
/// dart run tool/mapping_conformance.dart --feed ranking
/// dart run tool/mapping_conformance.dart --feed popular --update
/// ```
///
/// `--update` regenerates the golden from the legacy typed adapter, so the
/// golden records the adapter's behavior rather than the declarative engine's
/// own output.
Future<void> main(List<String> args) async {
  final feed = _option(args, '--feed') ?? 'popular';
  final fixturePath = _option(args, '--fixture') ?? 'bpi/testing/$feed.json';
  final goldenPath =
      _option(args, '--golden') ?? 'test/fixtures/declarative/$feed.json';
  final update = args.contains('--update');

  final fixture = _readJson(fixturePath);
  if (fixture is! Map<String, dynamic>) {
    stderr.writeln('Fixture must be a JSON object: $fixturePath');
    exitCode = 2;
    return;
  }

  if (update) {
    final page = await _legacyPage(feed, fixture);
    final canonical = [
      for (final video in page.data) canonicalVideoJson(video),
    ];
    _writeJson(goldenPath, canonical);
    stdout.writeln('Wrote $goldenPath (${canonical.length} items)');
    return;
  }

  final actual = await _declarativePage(feed, fixture);
  final expected = _readJson(goldenPath);
  final differences = diffJson(expected, actual);
  if (differences.isEmpty) {
    stdout.writeln('$feed: ${actual.length} items conform to $goldenPath');
    return;
  }

  stderr.writeln(
    '$feed: ${differences.length} conformance difference(s) in $goldenPath',
  );
  for (final difference in differences.take(20)) {
    stderr.writeln(
      '  ${difference.path}: expected ${difference.expected}, '
      'actual ${difference.actual}',
    );
  }
  exitCode = 1;
}

Future<List<Map<String, Object?>>> _declarativePage(
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
    _ => throw ArgumentError.value(feed, 'feed', 'expected popular or ranking'),
  };
  final result = await source.fetchFeed();
  final page = switch (result) {
    Success(:final success) => success,
    Error(:final error) => throw error,
  };
  return [for (final video in page.data) canonicalVideoJson(video)];
}

Future<Page<VideoModel>> _legacyPage(
  String feed,
  Map<String, dynamic> fixture,
) async {
  final network = switch (feed) {
    'popular' => _FixtureNetwork(
      popular: NetworkBiliPopularResponse.fromJson(fixture),
    ),
    'ranking' => _FixtureNetwork(
      ranking: NetworkBiliRankingResponse.fromJson(fixture),
    ),
    _ => throw ArgumentError.value(feed, 'feed', 'expected popular or ranking'),
  };
  final source = switch (feed) {
    'popular' => BiliPopularVideoFeedRemoteDataSource(network: network),
    'ranking' => BiliRankingVideoFeedRemoteDataSource(network: network),
    _ => throw ArgumentError.value(feed, 'feed', 'expected popular or ranking'),
  };
  final result = await source.fetchFeed();
  return switch (result) {
    Success(:final success) => success,
    Error(:final error) => throw error,
  };
}

final class _FixtureNetwork({
  final NetworkBiliPopularResponse? popular,
  final NetworkBiliRankingResponse? ranking,
}) implements NetworkBiliFeedDataSource {
  @override
  Future<NetworkBiliPopularResponse> getPopular({
    int page = 1,
    int pageSize = 20,
  }) async => popular ?? (throw StateError('popular fixture is not available'));

  @override
  Future<NetworkBiliRankingResponse> getRanking({
    int rankingId = 0,
    String type = 'all',
  }) async => ranking ?? (throw StateError('ranking fixture is not available'));
}

Object? _readJson(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    throw FileSystemException('JSON file not found', path);
  }
  return jsonDecode(file.readAsStringSync());
}

void _writeJson(String path, Object? value) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(value)}\n',
  );
}

String? _option(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index == -1 || index + 1 >= args.length) return null;
  return args[index + 1];
}
