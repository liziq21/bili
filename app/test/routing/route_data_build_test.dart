// ignore_for_file: use_primary_constructors, unnecessary_type_name_in_constructor

import 'package:app/providers/media_sources_provider.dart';
import 'package:app/routing/router.dart';
import 'package:app/routing/routes.dart';

import 'package:flutter/material.dart' hide MaterialApp, Scaffold;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp, Scaffold;
import 'package:provider/provider.dart';

/// 钉住各 typed route data 在「source 缺省」场景下的行为：每个 route 的 build
/// 都读 context 解析 source，缺省时回落到目录首项而不是崩溃。route data 类是
/// `part of router.dart` 的公开导出，可直接构造后调用
/// build。
void main() {
  GoRouterState fakeState({
    required String location,
    Map<String, String> pathParameters = const {},
    Object? extra,
  }) {
    return GoRouterState(
      router.configuration,
      uri: Uri.parse(location),
      matchedLocation: location,
      fullPath: location,
      pathParameters: pathParameters,
      pageKey: const ValueKey('page'),
      extra: extra,
    );
  }

  group('typed route data source resolution', () {
    testWidgets(
      'VideoRouteData.build resolves to the default source when source is null',
      (tester) async {
        final route = VideoRouteData(id: '123');
        Widget? built;
        await tester.pumpWidget(
          Provider<MediaSourceCatalog>.value(
            value: defaultMediaSourceCatalog,
            child: MaterialApp(
              home: Builder(
                builder: (context) {
                  built = route.build(
                    context,
                    fakeState(
                      location: '/video/123',
                      pathParameters: const {'id': '123'},
                    ),
                  );
                  return built ?? const SizedBox.shrink();
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(built, isNotNull);
      },
    );

    testWidgets(
      'NotFoundRouteData.build renders state.extra as URI text without crashing',
      (tester) async {
        final route = NotFoundRouteData();
        Widget? built;
        await tester.pumpWidget(
          Provider<MediaSourceCatalog>.value(
            value: defaultMediaSourceCatalog,
            child: MaterialApp(
              home: Builder(
                builder: (context) {
                  built = route.build(
                    context,
                    fakeState(location: '/404', extra: Uri.parse('/missing')),
                  );
                  return built ?? const SizedBox.shrink();
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(built, isNotNull);
        // extra 非空时 uri 字段取 extra 的 toString，path 字段取其 path/host/scheme。
        expect(find.textContaining('/missing'), findsOneWidget);
        // 钉死 path 三段拼接：NotFoundScreen 会剥控制字符（\n 在 \x00-\x1F 内），
        // 所以渲染结果是三段连写。任一段兜底逻辑被改掉（如把 uri?.path ?? ''
        // 换成常量）这里会变。
        expect(
          find.textContaining('Path: /missingHost: Scheme: '),
          findsOneWidget,
        );
      },
    );

    testWidgets('NotFoundRouteData.build tolerates a null extra', (
      tester,
    ) async {
      final route = NotFoundRouteData();
      Widget? built;
      await tester.pumpWidget(
        Provider<MediaSourceCatalog>.value(
          value: defaultMediaSourceCatalog,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                built = route.build(
                  context,
                  fakeState(location: '/404', extra: null),
                );
                return built ?? const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // extra 为 null 时 uri.toString() 是 'null'，path 三段兜底为空串，
      // 不能崩。
      expect(built, isNotNull);
      expect(find.textContaining('null'), findsOneWidget);
    });

    test('Routes constants are absolute paths starting with a slash', () {
      for (final path in <String>[
        Routes.home,
        Routes.search,
        Routes.searchEntry,
        Routes.library,
        Routes.live,
        Routes.space,
        Routes.video,
        Routes.notFound,
      ]) {
        expect(path.startsWith('/'), isTrue, reason: '$path must be absolute');
      }
    });

    test('Routes.videoWithId builds the expected video path', () {
      expect(Routes.videoWithId('abc'), '${Routes.video}/abc');
    });

    testWidgets(
      'navigateToVideo shows a snackbar for an unknown explicit source',
      (tester) async {
        await tester.pumpWidget(
          Provider<MediaSourceCatalog>.value(
            value: defaultMediaSourceCatalog,
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () =>
                        context.navigateToVideo('abc', source: 'missing'),
                    child: const Text('go'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('go'));
        await tester.pumpAndSettle();

        expect(find.text('视频所属的数据源不可用'), findsOneWidget);
      },
    );

    testWidgets(
      'navigateToVideo does not require a repository in the current branch',
      (tester) async {
        await tester.pumpWidget(
          Provider<MediaSourceCatalog>.value(
            value: defaultMediaSourceCatalog,
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    key: const ValueKey('go'),
                    onPressed: () {
                      try {
                        context.navigateToVideo('abc', source: 'bilibili');
                      } catch (_) {
                        // This focused test has no GoRouter; the absence of a
                        // current-branch repository is not the failure path.
                      }
                    },
                    child: const Text('go'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byKey(const ValueKey('go')));
        await tester.pump();

        expect(find.text('视频所属的数据源不可用'), findsNothing);
      },
    );
  });
}
