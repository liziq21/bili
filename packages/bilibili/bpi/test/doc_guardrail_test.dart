import 'dart:io';

import 'package:test/test.dart';

/// One public endpoint method, its backing fixtures, and the documentation
/// table row that records it.
///
/// [method] must match a method declared in `lib/src/network_*_data_source.dart`,
/// every name in [fixtures] must match a file in `testing/`, and [docCell] must
/// match a `Fixture` cell in both `AGENTS.md` and `testing/README.md`.
///
/// This table is written out by hand on purpose. Deriving it from the source
/// files, the fixture directory or the documentation would make the guardrail
/// compare a value with itself and detect nothing.
///
/// [docCell] is explicit rather than defaulted to the fixture name because the
/// two wildcard rows in the documentation cover more files than any one method
/// owns. Inferring the cell from the fixture name would let `search_*.json`
/// stand in for `search_suggest.json` and `search_all.json`, which have their
/// own rows because they are separate endpoints with separate sources.
final class EndpointSpec {
  const EndpointSpec({
    required this.method,
    required this.fixtures,
    required this.docCell,
  });

  final String method;
  final List<String> fixtures;

  /// The `Fixture` cell text as written in the documentation tables, without
  /// the surrounding backticks and without a directory part. May contain a `*`
  /// wildcard.
  ///
  /// The two tables spell the same cell differently — `AGENTS.md` writes
  /// `testing/popular.json`, `testing/README.md` writes `popular.json` — so the
  /// cell is compared on its file-name part alone.
  final String docCell;

  /// The documentation cells this row is responsible for. Only meaningful when
  /// [docCell] is a wildcard.
  Set<String> get fixtureNames => fixtures.toSet();
}

/// Every public endpoint method in the package.
///
/// Three documented exceptions to a strict one-method-one-fixture rule:
///
/// * The eleven `search*` type methods share the single `search_*.json`
///   wildcard row in both documentation tables; each still keeps its own
///   concrete fixture.
/// * `reply_*.json` is a wildcard row too, and `getReplyList` spans two
///   endpoints: `/x/v2/reply` for a paged read and `/x/v2/reply/main` when a
///   server continuation offset is supplied, so it owns two fixtures.
/// * `getSuggests` calls `/main/suggest`, not the WBI search endpoints, so its
///   fixture is named `search_suggest.json` without being a search-type
///   fixture, and it has its own row rather than sharing `search_*.json`.
const endpointSpecs = <EndpointSpec>[
  EndpointSpec(
    method: 'getPopular',
    fixtures: ['popular.json'],
    docCell: 'popular.json',
  ),
  EndpointSpec(
    method: 'getRanking',
    fixtures: ['ranking.json'],
    docCell: 'ranking.json',
  ),
  EndpointSpec(
    method: 'getLiveRoomDetail',
    fixtures: ['live_room_detail.json'],
    docCell: 'live_room_detail.json',
  ),
  EndpointSpec(
    method: 'getLiveRoomPlayInfo',
    fixtures: ['live_room_play_info.json'],
    docCell: 'live_room_play_info.json',
  ),
  EndpointSpec(
    method: 'searchAll',
    fixtures: ['search_all.json'],
    docCell: 'search_all.json',
  ),
  EndpointSpec(
    method: 'searchArticle',
    fixtures: ['search_article.json'],
    docCell: 'search_*.json',
  ),
  EndpointSpec(
    method: 'searchBiliUser',
    fixtures: ['search_bili_user.json'],
    docCell: 'search_*.json',
  ),
  EndpointSpec(
    method: 'searchLive',
    fixtures: ['search_live.json'],
    docCell: 'search_*.json',
  ),
  EndpointSpec(
    method: 'searchLiveRoom',
    fixtures: ['search_live_room.json'],
    docCell: 'search_*.json',
  ),
  EndpointSpec(
    method: 'searchLiveUser',
    fixtures: ['search_live_user.json'],
    docCell: 'search_*.json',
  ),
  EndpointSpec(
    method: 'searchMediaBangumi',
    fixtures: ['search_media_bangumi.json'],
    docCell: 'search_*.json',
  ),
  EndpointSpec(
    method: 'searchMediaFt',
    fixtures: ['search_media_ft.json'],
    docCell: 'search_*.json',
  ),
  EndpointSpec(
    method: 'searchPhoto',
    fixtures: ['search_photo.json'],
    docCell: 'search_*.json',
  ),
  EndpointSpec(
    method: 'searchTopic',
    fixtures: ['search_topic.json'],
    docCell: 'search_*.json',
  ),
  EndpointSpec(
    method: 'searchVideo',
    fixtures: ['search_video.json'],
    docCell: 'search_*.json',
  ),
  EndpointSpec(
    method: 'getSuggests',
    fixtures: ['search_suggest.json'],
    docCell: 'search_suggest.json',
  ),
  EndpointSpec(
    method: 'getUserCard',
    fixtures: ['user_card.json'],
    docCell: 'user_card.json',
  ),
  EndpointSpec(
    method: 'getVideoDetail',
    fixtures: ['video_detail.json'],
    docCell: 'video_detail.json',
  ),
  EndpointSpec(
    method: 'getVideoRelation',
    fixtures: ['video_relation.json'],
    docCell: 'video_relation.json',
  ),
  EndpointSpec(
    method: 'getRelatedVideos',
    fixtures: ['related_videos.json'],
    docCell: 'related_videos.json',
  ),
  EndpointSpec(
    method: 'getReplyList',
    fixtures: ['reply_list.json', 'reply_list_main.json'],
    docCell: 'reply_*.json',
  ),
  EndpointSpec(
    method: 'getReplyReplyList',
    fixtures: ['reply_reply_list.json'],
    docCell: 'reply_*.json',
  ),
  EndpointSpec(
    method: 'getPlayUrl',
    fixtures: ['play_url.json'],
    docCell: 'play_url.json',
  ),
  EndpointSpec(
    method: 'getPlayerInfo',
    fixtures: ['player_v2.json'],
    docCell: 'player_v2.json',
  ),
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

/// The variable a fixture-keyed loop binds its map key to, as the search-type
/// capture loop does with `final fileName = entry.key;`.
final RegExp _mapKeyLoopVariable = RegExp(
  r'^\s*final\s+([A-Za-z_]\w*)\s*=\s*entry\.key\s*;',
  multiLine: true,
);

/// The header of the `for` loop that walks the fixture table, binding each map
/// key to a loop variable.
final RegExp _fixtureLoopHeader = RegExp(
  r'for\s*\(\s*final\s+\w+\s+in\s+[A-Za-z_]\w*\.entries\s*\)',
);

/// The `saveResponse` call that writes the current loop iteration's fixture.
final RegExp _saveResponseInLoop = RegExp(
  r"saveResponse\(\s*'testing/\$\w+\??'",
);

/// The body of the fixture-enumerating loop, or `null` when it cannot be
/// located.
///
/// Scans forward from the loop header to the `}` closing its body at the same
/// nesting depth. Anchoring the write check to that span is what makes it
/// meaningful: a `saveResponse('testing/$name', ...)` sitting in an unrelated
/// branch of the script would otherwise satisfy it, and the guardrail would
/// keep reporting the fixture loop as writing its fixtures after the loop had
/// stopped writing them.
String? _fixtureLoopBody() {
  final script = File('tool/capture/fetch_fixtures.dart').readAsStringSync();
  final header = _fixtureLoopHeader.firstMatch(script);
  if (header == null) return null;
  var depth = 0;
  for (var i = header.end; i < script.length; i++) {
    final c = script[i];
    if (c == '{') {
      depth++;
    } else if (c == '}') {
      if (depth == 0) return script.substring(header.end, i);
      depth--;
    }
  }
  return null;
}

/// Runs before the guardrail reads anything from disk, so that being launched
/// from the wrong working directory reports itself as such instead of looking
/// like an empty fixture directory.
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
    if (row.length <= column) continue;
    cells.add(row[column]);
  }
  return cells;
}

/// Strips the surrounding backticks and any `testing/` directory part so cell
/// text can be compared with [EndpointSpec.docCell]. `AGENTS.md` writes
/// `testing/popular.json` where `testing/README.md` writes `popular.json`.
String _unquote(String cell) {
  final unquoted = cell.replaceAll('`', '').trim();
  const prefix = 'testing/';
  return unquoted.startsWith(prefix)
      ? unquoted.substring(prefix.length)
      : unquoted;
}

/// Expands a `Fixture` cell into the file names it stands for on disk.
///
/// A cell without a `*` names exactly one file; a wildcard cell names every
/// file matching it. Used both to expand the cells read from the documentation
/// and to check what a spec's declared cell stands for, so the two readings
/// cannot drift apart.
Set<String> _expandCell(String cell, Set<String> onDisk) {
  if (!cell.contains('*')) return {cell};
  final pattern = RegExp('^${RegExp.escape(cell).replaceAll(r'\*', '.*')}\$');
  return onDisk.where(pattern.hasMatch).toSet();
}

/// Checks that one documentation table records every method in the spec table,
/// and that every cell it lists is claimed by exactly the methods that declare
/// it.
///
/// The second half matters as much as the first. Checking only that every
/// fixture is mentioned somewhere lets the `search_*.json` wildcard stand in
/// for the `search_suggest.json` and `search_all.json` rows: delete those two
/// rows and the wildcard still matches their files, so a coverage-only
/// assertion stays green while the documentation has lost a source record.
void _assertDocumentationTableCoversSpec(String documentPath) {
  final cells = _fixtureColumn(
    File(documentPath).readAsStringSync(),
    documentPath,
  );
  expect(
    cells,
    isNotEmpty,
    reason: '$documentPath has no rows in its fixture table.',
  );

  final quoted = cells.map(_unquote).toList();

  final duplicates =
      quoted
          .where((c) => quoted.where((d) => d == c).length > 1)
          .toSet()
          .toList()
        ..sort();
  expect(
    duplicates,
    isEmpty,
    reason:
        '$documentPath records these `Fixture` cells more than once. A '
        'duplicate row can disagree with the row above it about which source '
        'or endpoint it belongs to, while the coverage comparison below still '
        'sees the same set. Remove the duplicate rows.',
  );

  for (final spec in endpointSpecs) {
    expect(
      quoted,
      contains(spec.docCell),
      reason:
          '${spec.method} declares its `Fixture` cell as ${spec.docCell}, '
          'which $documentPath does not contain. Add the row back.',
    );
  }

  // The coverage comparison below is a set comparison, so it stays green when
  // the documentation records a file under the wrong method: swapping
  // getPopular's cell for ranking.json leaves the union untouched. Bind each
  // spec to the cell it declares, so a row pointing at another method's
  // fixture fails here instead.
  final onDiskForSpecs = _fixturesOnDisk().toSet();
  for (final spec in endpointSpecs) {
    final cellCovers = _expandCell(spec.docCell, onDiskForSpecs);
    expect(
      spec.fixtureNames.difference(cellCovers),
      isEmpty,
      reason:
          '${spec.method} declares `Fixture` cell ${spec.docCell}, which in '
          '$documentPath stands for $cellCovers and therefore does not cover '
          'its registered fixture ${spec.fixtures}. The row points at another '
          "method's entry, or the `fixtures` list is wrong.",
    );
  }

  // Expand every wildcard cell against the files it actually matches, so a
  // stale prefix cannot keep passing, then require the union to be exactly the
  // set of files the spec table claims.
  final onDisk = _fixturesOnDisk().toSet();
  final covered = <String>{};
  for (final cell in quoted) {
    expect(
      cell,
      isNotEmpty,
      reason: '$documentPath has a `Fixture` row with an empty cell.',
    );
    if (!cell.contains('*')) {
      expect(
        onDisk,
        contains(cell),
        reason:
            '$documentPath documents $cell, which is not in the testing/ '
            'directory.',
      );
      covered.add(cell);
      continue;
    }
    final pattern = RegExp('^${RegExp.escape(cell).replaceAll(r'\*', '.*')}\$');
    final matches = onDisk.where(pattern.hasMatch).toList()..sort();
    expect(
      matches,
      isNotEmpty,
      reason:
          '$documentPath documents the wildcard $cell, which matches none of '
          'the files in testing/.',
    );
    covered.addAll(matches);
  }

  final claimed = <String>{
    for (final spec in endpointSpecs) ...spec.fixtureNames,
  };
  expect(
    onDisk.difference(covered).toList()..sort(),
    isEmpty,
    reason:
        'These fixtures exist in testing/ but $documentPath does not record '
        'them.',
  );
  expect(
    covered.difference(claimed).toList()..sort(),
    isEmpty,
    reason:
        '$documentPath records these fixtures, but no endpoint method in '
        'endpointSpecs claims them.',
  );
}

void main() {
  setUpAll(_requirePackageRoot);

  final fixturesOnDisk = _fixturesOnDisk();

  group('bpi endpoint documentation guardrail', () {
    test('every declared service method is registered in the spec table', () {
      final declared = <String>{};
      final dataSourceDirectory = Directory('lib/src');
      final names =
          dataSourceDirectory
              .listSync()
              .whereType<File>()
              .map((file) => file.uri.pathSegments.last)
              .where(
                (name) =>
                    name.startsWith('network_') &&
                    name.endsWith('_data_source.dart'),
              )
              .toList()
            ..sort();
      expect(
        names,
        isNotEmpty,
        reason: 'No data source files were found in lib/src.',
      );

      for (final name in names) {
        final source = File('lib/src/$name').readAsStringSync();
        declared.addAll(
          _methodDeclaration.allMatches(source).map((m) => m.group(2)!),
        );
      }
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
            'fixture is undocumented. Add the method with its fixture names and '
            'its documentation cell to the table in this file, plus rows in '
            'bpi/AGENTS.md and testing/README.md.',
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

    test('the endpoint table in AGENTS.md records every registered method', () {
      _assertDocumentationTableCoversSpec('AGENTS.md');
    });

    test(
      'the fixture table in testing/README.md records every registered method',
      () {
        _assertDocumentationTableCoversSpec('testing/README.md');
      },
    );

    test('every fixture can be written again by the capture script', () {
      final script = File('tool/capture/fetch_fixtures.dart');
      expect(
        script.existsSync(),
        isTrue,
        reason: 'tool/capture/fetch_fixtures.dart is missing.',
      );
      final source = script.readAsStringSync();

      // A fixture is written either through a literal
      // `saveResponse('testing/<name>.json', ...)` call or through a loop over
      // a table of fixture names. Matching the bare file name anywhere in the
      // file would also match the `shouldFetch('testing/<name>.json')` guard
      // of a branch whose fetch and write had been deleted, which is exactly
      // the drift this test exists for.
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

    test('the capture loop still writes the fixtures it enumerates', () {
      final source = File('tool/capture/fetch_fixtures.dart')
          .readAsStringSync();
      final tableDriven = _mapKeyFixtureName
          .allMatches(source)
          .map((m) => m.group(1)!)
          .toSet();
      if (tableDriven.isEmpty) {
        return;
      }
      final writers = _mapKeyLoopVariable
          .allMatches(source)
          .map((m) => m.group(1)!)
          .where((name) => _saveResponseWriting(name).hasMatch(source))
          .toList();

      expect(
        writers,
        isNotEmpty,
        reason:
            'tool/capture/fetch_fixtures.dart lists fixtures as map keys ('
            '${tableDriven.join(', ')}) but no loop over that table writes '
            'them: the variable holding the key never reaches a saveResponse '
            'call, so those fixtures are declared and never captured.',
      );
    });
  });
}
