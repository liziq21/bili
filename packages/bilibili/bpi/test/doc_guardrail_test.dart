import 'dart:io';

import 'package:test/test.dart';

/// One public endpoint method and the fixtures that back it.
///
/// [method] must match a method declared in `lib/src/network_*_data_source.dart`
/// and every name in [fixtures] must match a file in `testing/`.
///
/// This table is written out by hand on purpose. Deriving it from the source
/// files, the fixture directory or the documentation would make the guardrail
/// compare a value with itself and detect nothing.
final class EndpointSpec {
  const EndpointSpec({required this.method, required this.fixtures});

  final String method;
  final List<String> fixtures;
}

/// Every public endpoint method in the package, with its backing fixtures.
///
/// Three documented exceptions to a strict one-method-one-fixture rule:
///
/// * The twelve `search*` methods share the single `search_*.json` wildcard row
///   in both documentation tables; each still keeps its own concrete fixture.
/// * `reply_*.json` is a wildcard row too, and `getReplyList` spans two
///   endpoints: `/x/v2/reply` for a paged read and `/x/v2/reply/main` when a
///   server continuation offset is supplied, so it owns two fixtures.
/// * `getSuggests` calls `/main/suggest`, not the WBI search endpoints, so its
///   fixture is named `search_suggest.json` without being a search-type fixture.
const endpointSpecs = <EndpointSpec>[
  EndpointSpec(method: 'getPopular', fixtures: ['popular.json']),
  EndpointSpec(method: 'getRanking', fixtures: ['ranking.json']),
  EndpointSpec(
    method: 'getLiveRoomDetail',
    fixtures: ['live_room_detail.json'],
  ),
  EndpointSpec(
    method: 'getLiveRoomPlayInfo',
    fixtures: ['live_room_play_info.json'],
  ),
  EndpointSpec(method: 'searchAll', fixtures: ['search_all.json']),
  EndpointSpec(method: 'searchArticle', fixtures: ['search_article.json']),
  EndpointSpec(method: 'searchBiliUser', fixtures: ['search_bili_user.json']),
  EndpointSpec(method: 'searchLive', fixtures: ['search_live.json']),
  EndpointSpec(method: 'searchLiveRoom', fixtures: ['search_live_room.json']),
  EndpointSpec(method: 'searchLiveUser', fixtures: ['search_live_user.json']),
  EndpointSpec(
    method: 'searchMediaBangumi',
    fixtures: ['search_media_bangumi.json'],
  ),
  EndpointSpec(method: 'searchMediaFt', fixtures: ['search_media_ft.json']),
  EndpointSpec(method: 'searchPhoto', fixtures: ['search_photo.json']),
  EndpointSpec(method: 'searchTopic', fixtures: ['search_topic.json']),
  EndpointSpec(method: 'searchVideo', fixtures: ['search_video.json']),
  EndpointSpec(method: 'getSuggests', fixtures: ['search_suggest.json']),
  EndpointSpec(method: 'getUserCard', fixtures: ['user_card.json']),
  EndpointSpec(method: 'getVideoDetail', fixtures: ['video_detail.json']),
  EndpointSpec(method: 'getVideoRelation', fixtures: ['video_relation.json']),
  EndpointSpec(method: 'getRelatedVideos', fixtures: ['related_videos.json']),
  EndpointSpec(
    method: 'getReplyList',
    fixtures: ['reply_list.json', 'reply_list_main.json'],
  ),
  EndpointSpec(
    method: 'getReplyReplyList',
    fixtures: ['reply_reply_list.json'],
  ),
  EndpointSpec(method: 'getPlayUrl', fixtures: ['play_url.json']),
  EndpointSpec(method: 'getPlayerInfo', fixtures: ['player_v2.json']),
];

/// Matches an abstract method declaration such as
/// `  Future<NetworkBiliPopularResponse> getPopular({`.
///
/// The leading identifier class rejects private helpers: an endpoint method is
/// the only public member these data source files declare. The lazy return-type
/// group copes with nested generics such as `Future<List<NetworkReplyData>>`,
/// where stopping at the first `>` would leave a stray `>` before the method
/// name and the match would fail.
final RegExp _methodDeclaration = RegExp(
  r'^[ \t]*Future<(.+?)>[ \t]+([A-Za-z]\w*)[ \t]*\(',
  multiLine: true,
);

final RegExp _markdownSeparatorCell = RegExp(r'^:?-+:?$');

/// A fixture name written straight into a `saveResponse` call, as the
/// single-endpoint capture branches do.
final RegExp _literalSaveResponse = RegExp(
  r"saveResponse\(\s*'testing/([A-Za-z0-9_]+\.json)'",
);

/// A fixture name used as a map key, as the search-type capture loop does:
/// `saveResponse('testing/$fileName', captured)` over a
/// `<String, String>{'search_video.json': 'video', ...}` table.
final RegExp _mapKeyFixtureName = RegExp(
  r"^\s*'([A-Za-z0-9_]+\.json)':",
  multiLine: true,
);

/// Runs once before the guardrail reads anything from disk, so that being
/// launched from the wrong working directory reports itself as such instead of
/// looking like an empty fixture directory.
void _requirePackageRoot() {
  for (final relative in ['lib/src', 'testing', 'AGENTS.md']) {
    expect(
      FileSystemEntity.typeSync(relative) != FileSystemEntityType.notFound,
      isTrue,
      reason:
          'bpi tests must run with the package directory as the working '
          'directory; $relative is missing. Run dart test from '
          'packages/bilibili/bpi.',
    );
  }
}

List<String> _dataSourceFiles() {
  return Directory('lib/src')
      .listSync()
      .whereType<File>()
      .map((file) => file.uri.pathSegments.last)
      .where(
        (name) =>
            name.startsWith('network_') && name.endsWith('_data_source.dart'),
      )
      .toList()
    ..sort();
}

/// Every public endpoint method name declared across the data source files.
Set<String> _declaredServiceMethods() {
  final methods = <String>{};
  for (final name in _dataSourceFiles()) {
    final source = File('lib/src/$name').readAsStringSync();
    methods.addAll(
      _methodDeclaration.allMatches(source).map((m) => m.group(2)!),
    );
  }
  return methods;
}

/// Every fixture file name in `testing/`, sorted.
List<String> _fixturesOnDisk() {
  return Directory('testing')
      .listSync()
      .whereType<File>()
      .map((file) => file.uri.pathSegments.last)
      .where((name) => name.endsWith('.json'))
      .toList()
    ..sort();
}

List<String> _markdownCells(String line) {
  return line
      .replaceFirst(RegExp(r'^\|'), '')
      .replaceFirst(RegExp(r'\|$'), '')
      .split('|')
      .map((cell) => cell.trim())
      .toList();
}

/// The `Fixture` column of the first markdown table in [source] whose header
/// names that column.
///
/// Both documentation tables are found this way rather than by line number, so
/// inserting a section above a table does not break the guardrail. Rows of a
/// different width than the header are skipped instead of being read out of
/// range.
List<String> _fixtureColumn(String source, String documentPath) {
  final lines = source
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.startsWith('|'))
      .toList();

  final headerIndex = lines.indexWhere(
    (line) => _markdownCells(line).contains('Fixture'),
  );
  expect(
    headerIndex,
    isNot(-1),
    reason:
        '$documentPath must document its fixtures in a table with a '
        '`Fixture` column.',
  );

  final column = _markdownCells(lines[headerIndex]).indexOf('Fixture');
  final cells = <String>[];
  for (final line in lines.skip(headerIndex + 1)) {
    final row = _markdownCells(line);
    if (row.every((cell) => _markdownSeparatorCell.hasMatch(cell))) continue;
    if (row.length <= column) {
      continue;
    }
    cells.add(row[column]);
  }
  return cells;
}

/// Strips the surrounding backticks and the `testing/` prefix so that the same
/// cell text can be compared against the bare file names in `testing/`.
String _bareFixtureName(String cell) {
  final unquoted = cell.replaceAll('`', '').trim();
  const prefix = 'testing/';
  return unquoted.startsWith(prefix)
      ? unquoted.substring(prefix.length)
      : unquoted;
}

/// Resolves the `Fixture` cells of one documentation table against the files
/// actually present in `testing/`.
///
/// A literal cell must name a file that exists. A wildcard cell such as
/// `search_*.json` must expand to at least one real file, so a stale prefix
/// cannot quietly keep passing after the fixtures behind it are renamed.
Set<String> _documentedFixtures(
  List<String> cells,
  Set<String> onDisk,
  String documentPath,
) {
  final documented = <String>{};
  for (final cell in cells) {
    final name = _bareFixtureName(cell);
    expect(
      name,
      isNotEmpty,
      reason: '$documentPath has a `Fixture` row with an empty cell.',
    );
    if (!name.contains('*')) {
      expect(
        onDisk,
        contains(name),
        reason:
            '$documentPath documents $name, which is not in the testing/ '
            'directory.',
      );
      documented.add(name);
      continue;
    }
    final pattern = RegExp('^${RegExp.escape(name).replaceAll(r'\*', '.*')}\$');
    final matches = onDisk.where(pattern.hasMatch).toList()..sort();
    expect(
      matches,
      isNotEmpty,
      reason:
          '$documentPath documents the wildcard $name, which matches none of '
          'the files in testing/.',
    );
    documented.addAll(matches);
  }
  return documented;
}

void main() {
  setUpAll(_requirePackageRoot);

  final fixturesOnDisk = _fixturesOnDisk();

  group('bpi endpoint documentation guardrail', () {
    test('every declared service method is registered in the spec table', () {
      final declared = _declaredServiceMethods();
      expect(
        declared,
        isNotEmpty,
        reason: 'No endpoint methods were parsed out of lib/src.',
      );

      final registered = endpointSpecs.map((spec) => spec.method).toSet();
      expect(
        declared.difference(registered).toList()..sort(),
        isEmpty,
        reason:
            'These endpoint methods have no entry in endpointSpecs, so their '
            'fixture is undocumented. Add the method with its fixture names to '
            'the table in this file, plus rows in bpi/AGENTS.md and '
            'testing/README.md.',
      );
      expect(
        registered.difference(declared).toList()..sort(),
        isEmpty,
        reason:
            'endpointSpecs names methods that are not declared in '
            'lib/src/network_*_data_source.dart.',
      );
    });

    test('every registered fixture exists in testing/', () {
      for (final spec in endpointSpecs) {
        for (final fixture in spec.fixtures) {
          expect(
            File('testing/$fixture').existsSync(),
            isTrue,
            reason:
                '${spec.method} claims $fixture, which is missing from '
                'testing/.',
          );
        }
      }
    });

    test('every fixture in testing/ is claimed by exactly one method', () {
      final claims = <String, List<String>>{};
      for (final spec in endpointSpecs) {
        for (final fixture in spec.fixtures) {
          claims.putIfAbsent(fixture, () => []).add(spec.method);
        }
      }

      final unclaimed = fixturesOnDisk.toSet().difference(claims.keys.toSet());
      expect(
        unclaimed.toList()..sort(),
        isEmpty,
        reason:
            'These fixtures exist in testing/ but no endpoint method claims '
            'them, so no documentation row records them.',
      );

      for (final entry in claims.entries) {
        expect(
          entry.value,
          hasLength(1),
          reason:
              '${entry.key} is claimed by ${entry.value.join(', ')}; each '
              'fixture must back exactly one endpoint method.',
        );
      }
    });

    test('the endpoint table in AGENTS.md covers every fixture on disk', () {
      final onDisk = fixturesOnDisk.toSet();
      final cells = _fixtureColumn(
        File('AGENTS.md').readAsStringSync(),
        'AGENTS.md',
      );
      expect(
        cells,
        isNotEmpty,
        reason: 'AGENTS.md has no rows in its endpoint table.',
      );

      final documented = _documentedFixtures(cells, onDisk, 'AGENTS.md');
      expect(
        onDisk.difference(documented).toList()..sort(),
        isEmpty,
        reason:
            'These fixtures exist in testing/ but the AGENTS.md endpoint '
            'table does not record them. Add a row under '
            '「已确认的来源与端点」.',
      );
    });

    test(
      'the fixture table in testing/README.md covers every file on disk',
      () {
        final onDisk = fixturesOnDisk.toSet();
        final cells = _fixtureColumn(
          File('testing/README.md').readAsStringSync(),
          'testing/README.md',
        );
        expect(
          cells,
          isNotEmpty,
          reason: 'testing/README.md has no rows in its fixture table.',
        );

        final documented = _documentedFixtures(
          cells,
          onDisk,
          'testing/README.md',
        );
        expect(
          onDisk.difference(documented).toList()..sort(),
          isEmpty,
          reason:
              'These fixtures exist in testing/ but the testing/README.md '
              'fixture table does not record them. Add a row under '
              '「Fixture 记录」.',
        );
      },
    );

    test('every fixture can be produced again by the capture script', () {
      final script = File('tool/capture/fetch_fixtures.dart');
      expect(
        script.existsSync(),
        isTrue,
        reason: 'tool/capture/fetch_fixtures.dart is missing.',
      );
      final source = script.readAsStringSync();

      // A fixture is captured either through a literal
      // `saveResponse('testing/<name>.json', ...)` call or through a loop whose
      // map keys are the fixture names, as the twelve search-type endpoints do.
      // Matching the bare file name anywhere in the file would also match the
      // `shouldFetch('testing/<name>.json')` guard of a branch whose fetch and
      // write were deleted, which is exactly the drift this test exists for.
      final written = <String>{
        for (final m in _literalSaveResponse.allMatches(source)) m.group(1)!,
        for (final m in _mapKeyFixtureName.allMatches(source)) m.group(1)!,
      };

      for (final fixture in fixturesOnDisk) {
        expect(
          written,
          contains(fixture),
          reason:
              '$fixture is never written by '
              'tool/capture/fetch_fixtures.dart, so it cannot be refreshed. '
              'Step 2 of 「新增 endpoint 流程」 in AGENTS.md requires a capture '
              'branch for every endpoint.',
        );
      }
    });
  });
}
