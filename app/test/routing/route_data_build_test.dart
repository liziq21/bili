// ignore_for_file: use_primary_constructors, unnecessary_type_name_in_constructor

import 'package:app/data/repository/video_detail_repository.dart';
import 'package:app/providers/media_sources_provider.dart';
import 'package:app/routing/router.dart';
import 'package:app/routing/routes.dart';

import 'package:data/data.dart';
import 'package:flutter/material.dart' hide MaterialApp, Scaffold;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp, Scaffold;
import 'package:provider/provider.dart';

/// 钉住各 typed route data 在「source 缺省」场景下的行为：每个 route 的 build
/// 都读 context 解析 source，缺省时回落到 [defaultMediaSources] 首项而不是
/// 崩溃。route data 类是 `part of router.dart` 的公开导出，可直接构造后调用
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
          Provider<List<MediaSource>>(
            create: (_) => defaultMediaSources,
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
          Provider<List<MediaSource>>(
            create: (_) => defaultMediaSources,
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
        Provider<List<MediaSource>>(
          create: (_) => defaultMediaSources,
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
      'navigateToVideo shows a snackbar when no VideoDetailRepository is in scope',
      (tester) async {
        // 读不到仓库时不 push 路由，而是弹 SnackBar：这是「数据源不支持详情」的
        // 唯一用户可见出口。push 分支需要真实 Navigator + 路由表，此处只钉兜底。
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () => context.navigateToVideo('abc'),
                    child: const Text('go'),
                  );
                },
              ),
            ),
          ),
        );
        await tester.tap(find.text('go'));
        await tester.pumpAndSettle();

        expect(
          find.text('当前数据源暂不支持查看视频详情'),
          findsOneWidget,
          reason: 'missing repo must surface a snackbar instead of pushing',
        );
      },
    );

    testWidgets(
      'navigateToVideo does not show the snackbar when a repo is in scope',
      (tester) async {
        // 仓库在位时走 push 分支，push 需要 GoRouter 在 context 上、目标页
        // 拉起 VideoScreen 需整套 provider 图——成本不抵收益。此处只钉
        // 「repo 读取本身没被改坏」：读取成功就不该进 SnackBar 分支。tap 后
        // 立即 pump（不 pumpAndSettle），push 抛 GoRouter 找不到的异常被
        // 吞掉，只看 SnackBar 没出现。
        await tester.pumpWidget(
          Provider<VideoDetailRepository?>(
            create: (_) => _StubVideoDetailRepository(),
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    return ElevatedButton(
                      key: const ValueKey('go'),
                      onPressed: () {
                        try {
                          context.navigateToVideo('abc');
                        } catch (_) {
                          // push 需要 GoRouter，此处必然抛；只关心没走
                          // SnackBar 分支。
                        }
                      },
                      child: const Text('go'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byKey(const ValueKey('go')));
        await tester.pump();

        expect(
          find.text('当前数据源暂不支持查看视频详情'),
          findsNothing,
          reason: 'repo in scope must not enter the snackbar fallback',
        );
      },
    );
  });
}

class _StubVideoDetailRepository implements VideoDetailRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
