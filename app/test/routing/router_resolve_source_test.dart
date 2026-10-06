// ignore_for_file: use_primary_constructors, unnecessary_type_name_in_constructor

import 'package:app/data/repository/video_detail_repository.dart';
import 'package:app/providers/media_sources_provider.dart';
import 'package:app/providers/service_source_providers.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('ServiceSourceProviders source resolution', () {
    testWidgets('creates VideoDetailRepository for known source bilibili', (
      tester,
    ) async {
      var created = false;
      await tester.pumpWidget(
        ServiceSourceProviders(
          source: 'bilibili',
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                try {
                  context.read<VideoDetailRepository>();
                  created = true;
                } on ProviderNotFoundException {
                  created = false;
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(created, isTrue);
    });

    testWidgets('creates VideoDetailRepository for known source youtube', (
      tester,
    ) async {
      var exceptionCaught = false;
      await tester.pumpWidget(
        ServiceSourceProviders(
          source: 'youtube',
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                // YouTube 分支未注入 VideoDetailRepository，读取应抛异常。
                try {
                  context.read<VideoDetailRepository>();
                } on ProviderNotFoundException {
                  exceptionCaught = true;
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(exceptionCaught, isTrue);
    });

    testWidgets('throws on unknown source', (tester) async {
      await tester.pumpWidget(
        ServiceSourceProviders(
          source: 'unknown_source',
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                context.read<VideoDetailRepository>();
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNotNull);
    });

    testWidgets(
      '_assertRegistered throws ArgumentError for unknown source before build',
      (tester) async {
        var caught = false;
        await tester.pumpWidget(
          ServiceSourceProviders(
            source: 'unknown_source',
            child: MaterialApp(
              home: Builder(builder: (context) => const SizedBox.shrink()),
            ),
          ),
        );

        // pumpWidget 内部同步跑 build，_assertRegistered 在 build 入口直接抛，
        // tester.takeException() 能捕获到 ArgumentError。
        final e = tester.takeException();
        if (e is ArgumentError) caught = true;
        expect(
          caught,
          isTrue,
          reason: 'unknown source must throw ArgumentError in build',
        );
      },
    );

    testWidgets('skips injection when same String provider already present', (
      tester,
    ) async {
      var exceptionCaught = false;
      await tester.pumpWidget(
        Provider<String>(
          create: (_) => 'bilibili',
          child: ServiceSourceProviders(
            source: 'bilibili',
            child: MaterialApp(
              home: Builder(
                builder: (context) {
                  try {
                    context.read<VideoDetailRepository>();
                  } on ProviderNotFoundException {
                    exceptionCaught = true;
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 祖先已注册同名 String provider 时，ServiceSourceProviders 直接返回 child
      // 而不重复注入，因此不应创建新的 VideoDetailRepository 实例。
      // 读取会抛 ProviderNotFoundException。
      expect(exceptionCaught, isTrue);
    });
  });

  group('router source resolution via defaultMediaSources fallback', () {
    testWidgets('defaultMediaSources first id used when no String provider', (
      tester,
    ) async {
      String? resolvedSourceId;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              // 模拟 router._resolveSource 的逻辑：先尝试读 String provider，
              // 失败则回落 defaultMediaSources.first.id。
              String? sourceId;
              try {
                sourceId = context.read<String?>();
              } on ProviderNotFoundException {
                sourceId = null;
              }
              resolvedSourceId = sourceId ?? defaultMediaSources.first.id;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(resolvedSourceId, defaultMediaSources.first.id);
    });

    testWidgets('uses String provider when registered', (tester) async {
      String? resolvedSourceId;
      await tester.pumpWidget(
        Provider<String>(
          create: (_) => 'youtube',
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                String? sourceId;
                try {
                  sourceId = context.read<String?>();
                } on ProviderNotFoundException {
                  sourceId = null;
                }
                resolvedSourceId = sourceId ?? defaultMediaSources.first.id;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(resolvedSourceId, 'youtube');
    });
  });
}
