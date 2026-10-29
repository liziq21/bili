import 'package:app/routing/routes.dart';
import 'package:app/routing/router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Collects every [GoRoute] in the routing table, together with the chain of
/// ancestors that leads to it.
///
/// [branchIndex] is the index of the owning [StatefulShellBranch] when the
/// route is nested inside the [StatefulShellRoute], otherwise null.
List<({String fullPath, int? branchIndex})> _collectRoutes(
  List<RouteBase> routes, {
  String parentPath = '',
  int? branchIndex,
}) {
  final collected = <({String fullPath, int? branchIndex})>[];
  for (final route in routes) {
    if (route is StatefulShellRoute) {
      for (final (index, branch) in route.branches.indexed) {
        collected.addAll(
          _collectRoutes(
            branch.routes,
            parentPath: parentPath,
            branchIndex: index,
          ),
        );
      }
      continue;
    }
    if (route is! GoRoute) {
      // Plain ShellRoute: contributes no path segment of its own.
      collected.addAll(
        _collectRoutes(
          route.routes,
          parentPath: parentPath,
          branchIndex: branchIndex,
        ),
      );
      continue;
    }
    final fullPath = _join(parentPath, route.path);
    collected.add((fullPath: fullPath, branchIndex: branchIndex));
    collected.addAll(
      _collectRoutes(
        route.routes,
        parentPath: fullPath,
        branchIndex: branchIndex,
      ),
    );
  }
  return collected;
}

String _join(String parentPath, String childPath) {
  final segments = <String>[
    ...parentPath.split('/'),
    ...childPath.split('/'),
  ].where((String segment) => segment.isNotEmpty);
  return '/${segments.join('/')}';
}

void main() {
  group('Router structure', () {
    late List<({String fullPath, int? branchIndex})> table;

    setUp(() {
      table = _collectRoutes(router.configuration.routes);
    });

    test('top level holds exactly one indexed shell and one plain shell', () {
      final topLevel = router.configuration.routes;
      expect(topLevel.whereType<StatefulShellRoute>().length, 1);
      expect(topLevel.whereType<ShellRoute>().length, 1);
    });

    test('the three bottom bar destinations are branch roots', () {
      final branchRoots = table
          .where(
            (({String fullPath, int? branchIndex}) e) => e.branchIndex != null,
          )
          .map((({String fullPath, int? branchIndex}) e) => e.fullPath)
          .toSet();
      expect(
        branchRoots,
        containsAll(<String>[Routes.home, Routes.searchEntry, Routes.library]),
      );
    });

    test('search result page stays a root level route outside every branch', () {
      final searchResult = table.firstWhere(
        (({String fullPath, int? branchIndex}) e) =>
            e.fullPath == Routes.search,
      );
      expect(
        searchResult.branchIndex,
        isNull,
        reason:
            'search result page must stay outside StatefulShellRoute branches',
      );
    });

    test('pushed secondary pages stay outside every branch', () {
      final secondary = <String>[
        '/${Routes.liveRelative}/:roomId',
        '/${Routes.spaceRelative}/:mid',
        '/${Routes.videoRelative}/:id',
        Routes.notFound,
      ];
      for (final path in secondary) {
        final entry = table.firstWhere(
          (({String fullPath, int? branchIndex}) e) => e.fullPath == path,
        );
        expect(
          entry.branchIndex,
          isNull,
          reason: '$path must stay outside StatefulShellRoute branches',
        );
      }
    });

    test('search entry branch does not own the search result page', () {
      final searchBranchIndex = table
          .firstWhere(
            (({String fullPath, int? branchIndex}) e) =>
                e.fullPath == Routes.searchEntry,
          )
          .branchIndex;
      final owned = table
          .where(
            (({String fullPath, int? branchIndex}) e) =>
                e.branchIndex == searchBranchIndex,
          )
          .map((({String fullPath, int? branchIndex}) e) => e.fullPath)
          .toSet();
      expect(owned, <String>{Routes.searchEntry});
    });

    test('no child GoRoute declares an absolute path', () {
      String? offender;
      void walk(List<RouteBase> routes) {
        for (final route in routes) {
          if (route is StatefulShellRoute) {
            for (final branch in route.branches) {
              walk(branch.routes);
            }
            continue;
          }
          if (route is! GoRoute) {
            walk(route.routes);
            continue;
          }
          for (final child in route.routes.whereType<GoRoute>()) {
            if (child.path.startsWith('/')) {
              offender = '${route.path} -> ${child.path}';
            }
          }
          walk(route.routes);
        }
      }

      walk(router.configuration.routes);
      expect(offender, isNull);
    });

    test('search result page resolves with its query intact', () {
      final match = router.configuration.findMatch(
        Uri.parse('${Routes.search}?keyword=abc'),
      );
      expect(match.fullPath, Routes.search);
      expect(match.uri.queryParameters['keyword'], 'abc');
    });

    group('Settings routes', () {
      for (final (path, expectedPath) in [
        (Routes.settings, '/settings'),
        (Routes.settingsPlayer, '/settings/player'),
        (Routes.settingsAppearance, '/settings/appearance'),
        (Routes.settingsHistory, '/settings/history'),
        (Routes.settingsLibrary, '/settings/library'),
        (Routes.settingsAdvanced, '/settings/advanced'),
        (Routes.danmakuSettings, '/settings/danmaku'),
      ]) {
        test('$expectedPath resolves outside every bottom bar branch', () {
          // Given a public settings destination and the production routes.
          expect(path, expectedPath);

          // When a direct location is matched by the real router.
          final match = router.configuration.findMatch(Uri.parse(path));
          final entries = table.where((entry) => entry.fullPath == path);

          // Then it resolves exactly once without belonging to a bottom branch.
          expect(match.error, isNull);
          expect(match.fullPath, expectedPath);
          expect(match.uri.path, expectedPath);
          expect(entries, hasLength(1));
          expect(entries.single.branchIndex, isNull);
        });
      }

      test('groups nest under settings while danmaku remains its sibling', () {
        // Given the existing plain shell for pushed secondary pages.
        final shell = router.configuration.routes
            .whereType<ShellRoute>()
            .single;

        // When its settings index and danmaku routes are located.
        final settings = shell.routes.whereType<GoRoute>().singleWhere(
          (route) => route.path == Routes.settings,
        );
        final danmaku = shell.routes.whereType<GoRoute>().where(
          (route) => route.path == Routes.danmakuSettings,
        );

        // Then all five children are relative and danmaku stays a sibling.
        expect(
          settings.routes.whereType<GoRoute>().map((route) => route.path),
          unorderedEquals([
            'player',
            'appearance',
            'history',
            'library',
            'advanced',
            'discovery',
          ]),
        );
        expect(danmaku, hasLength(1));
      });
    });
  });
}
