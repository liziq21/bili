import 'dart:io';

import 'package:test/test.dart';

final class EndpointSpec {
  const EndpointSpec({
    required this.method,
    required this.fixtures,
    required this.docCell,
  });

  final String method;
  final List<String> fixtures;
  final String docCell;

  Set<String> get fixtureNames => fixtures.toSet();
}

const endpointSpecs = <EndpointSpec>[
  EndpointSpec(
    method: 'searchVideos',
    fixtures: ['search_video.json'],
    docCell: 'search_video.json',
  ),
  EndpointSpec(
    method: 'searchChannels',
    fixtures: ['search_channel.json'],
    docCell: 'search_channel.json',
  ),
  EndpointSpec(
    method: 'searchPlaylists',
    fixtures: ['search_playlist.json'],
    docCell: 'search_playlist.json',
  ),
  EndpointSpec(
    method: 'getWatchNext',
    fixtures: ['watch_next.json'],
    docCell: 'watch_next.json',
  ),
  EndpointSpec(
    method: 'getComments',
    fixtures: ['comments.json'],
    docCell: 'comments.json',
  ),
  EndpointSpec(
    method: 'getPlayer',
    fixtures: ['player.json'],
    docCell: 'player.json',
  ),
  EndpointSpec(
    method: 'getSearchSuggestions',
    fixtures: ['search_suggest.json'],
    docCell: 'search_suggest.json',
  ),
  EndpointSpec(
    method: 'browseChannel',
    fixtures: ['browse.json', 'browse_continuation.json'],
    docCell: 'browse*.json',
  ),
  EndpointSpec(
    method: 'browsePlaylist',
    fixtures: ['browse_playlist.json'],
    docCell: 'browse_playlist.json',
  ),
  EndpointSpec(
    method: 'browseHomeFeed',
    fixtures: ['home_feed.json'],
    docCell: 'home_feed.json',
  ),
];

final RegExp _methodDeclaration = RegExp(
  r'^[ \t]*Future<(.+?)>[ \t]+([A-Za-z]\w*)[ \t]*\(',
  multiLine: true,
);

final RegExp _markdownSeparatorCell = RegExp(r'^:?-+:?$');

final RegExp _literalSaveResponse = RegExp(
  r"saveResponse\(\s*'testing/([A-Za-z0-9_]+\.json)'",
);

String _stripDartComments(String source) {
  final sb = StringBuffer();
  var i = 0;
  final n = source.length;
  while (i < n) {
    final ch = source[i];
    if (ch == '/' && i + 1 < n) {
      final next = source[i + 1];
      if (next == '/') {
        while (i < n && source[i] != '\n') {
          sb.write(' ');
          i++;
        }
        continue;
      }
      if (next == '*') {
        sb.write(' ');
        i++;
        sb.write(' ');
        i++;
        while (i < n) {
          if (source[i] == '*' && i + 1 < n && source[i + 1] == '/') {
            sb.write('  ');
            i += 2;
            break;
          }
          sb.write(source[i] == '\n' ? '\n' : ' ');
          i++;
        }
        continue;
      }
    }
    if (ch == "'" || ch == '"') {
      final quote = ch;
      sb.write(ch);
      i++;
      while (i < n) {
        final c = source[i];
        sb.write(c);
        i++;
        if (c == '\\' && i < n) {
          sb.write(source[i]);
          i++;
        } else if (c == quote) {
          break;
        }
      }
      continue;
    }
    sb.write(ch);
    i++;
  }
  return sb.toString();
}

void _requirePackageRoot() {
  for (final relative in ['lib/src', 'testing', 'AGENTS.md']) {
    expect(
      FileSystemEntity.typeSync(relative) != FileSystemEntityType.notFound,
      isTrue,
      reason:
          'ypi tests must run with the package directory as the working '
          'directory; $relative is missing. Run dart test from '
          'packages/youtube/ypi.',
    );
  }
}

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

List<String> _unquote(String cell) {
  var unquoted = cell.replaceAll('`', '').trim();
  unquoted = unquoted.replaceAll(RegExp(r'[（(].*?[）)]'), '').trim();
  final parts = unquoted
      .split('+')
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty);
  final result = <String>[];
  for (final part in parts) {
    const prefix = 'testing/';
    result.add(part.startsWith(prefix) ? part.substring(prefix.length) : part);
  }
  return result;
}

Set<String> _expandCell(String cell, Set<String> onDisk) {
  if (!cell.contains('*')) return {cell};
  final pattern = RegExp('^${RegExp.escape(cell).replaceAll(r'\*', '.*')}\$');
  return onDisk.where(pattern.hasMatch).toSet();
}

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

  final quoted = cells.expand(_unquote).toList();
  final onDisk = _fixturesOnDisk().toSet();

  for (final spec in endpointSpecs) {
    final specFixtures = spec.fixtureNames;
    expect(
      specFixtures.every(
        (f) => quoted.any((q) => _expandCell(q, onDisk).contains(f)),
      ),
      isTrue,
      reason:
          '${spec.method} expects fixtures ${spec.fixtures}, which $documentPath does not fully cover.',
    );
  }
}

void main() {
  setUpAll(_requirePackageRoot);

  final fixturesOnDisk = _fixturesOnDisk();

  group('ypi endpoint documentation guardrail', () {
    test('every declared service method is registered in the spec table', () {
      final source = File('lib/src/service/youtube_service.dart')
          .readAsStringSync();
      final declared = _methodDeclaration
          .allMatches(source)
          .map((m) => m.group(2)!)
          .where(
            (m) =>
                !m.startsWith('_') &&
                m != 'close' &&
                m != 'call' &&
                m != 'Function',
          )
          .toSet();

      expect(
        declared,
        isNotEmpty,
        reason: 'No endpoint methods were parsed out of YoutubeService.',
      );

      final registered = endpointSpecs.map((spec) => spec.method).toSet();
      expect(
        declared.difference(registered).toList()..sort(),
        isEmpty,
        reason:
            'These endpoint methods have no entry in endpointSpecs: ${declared.difference(registered)}',
      );
      expect(
        registered.difference(declared).toList()..sort(),
        isEmpty,
        reason: 'endpointSpecs names methods that are not declared in YoutubeService.',
      );
    });

    test('every registered fixture exists in testing/', () {
      for (final spec in endpointSpecs) {
        for (final fixture in spec.fixtures) {
          expect(
            File('testing/$fixture').existsSync(),
            isTrue,
            reason:
                '${spec.method} claims $fixture, which is missing from testing/.',
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
            'them: $unclaimed',
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
      expect(script.existsSync(), isTrue);
      final source = script.readAsStringSync();

      final written = <String>{
        for (final m in _literalSaveResponse.allMatches(
          _stripDartComments(source),
        ))
          m.group(1)!,
      };

      for (final fixture in fixturesOnDisk) {
        expect(
          written,
          contains(fixture),
          reason:
              '$fixture is never written by tool/capture/fetch_fixtures.dart.',
        );
      }
    });
  });
}
