import 'package:app/providers/media_sources_provider.dart';
import 'package:bilibili/bilibili.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtube/youtube.dart';

/// 仅提供 id 的假数据源，用于构造任意清单（真实 [Bili] 会起网络客户端）。
// ignore_for_file: use_primary_constructors, unnecessary_type_name_in_constructor

class _FakeSource extends MediaSource {
  _FakeSource(this.id);

  @override
  final String id;

  @override
  String get name => id;
}

void main() {
  final sources = <MediaSource>[_FakeSource('alpha'), _FakeSource('beta')];

  group('resolveMediaSourceId', () {
    test('returns the persisted id when it is in the list', () {
      expect(resolveMediaSourceId(sources, 'beta'), 'beta');
    });

    test('returns the first id when nothing was persisted', () {
      expect(resolveMediaSourceId(sources, null), 'alpha');
    });

    test('falls back to the first id for an unknown persisted value', () {
      // 脏值（源被下架 / 换了 id）必须回退而不是原样透传。
      expect(resolveMediaSourceId(sources, 'removed-source'), 'alpha');
    });

    test('returns an empty id for an empty list instead of throwing', () {
      // 清单为空时若取 first.id 会抛 StateError；契约是返回空标识。
      expect(resolveMediaSourceId(const <MediaSource>[], null), '');
      expect(resolveMediaSourceId(const <MediaSource>[], 'alpha'), '');
    });

    test('an empty persisted value falls back to the first id', () {
      expect(resolveMediaSourceId(sources, ''), 'alpha');
    });

    test(
      'is case sensitive, unlike the registry in ServiceSourceProviders',
      () {
        // 解析点与 service_source_providers 的 _registry 规则不同：后者
        // toLowerCase 后查表，这边按精确 id 比对。行为分叉就显式钉住。
        expect(resolveMediaSourceId(sources, 'ALPHA'), 'alpha');
      },
    );

    test('produces the same result for a single-source list', () {
      final single = <MediaSource>[_FakeSource('solo')];

      expect(resolveMediaSourceId(single, 'solo'), 'solo');
      expect(resolveMediaSourceId(single, null), 'solo');
      expect(resolveMediaSourceId(single, 'other'), 'solo');
    });

    test(
      'resolves the same persisted value identically across repeated calls',
      () {
        // HomeBloc 与 router 各解析一次；规则若带可变状态，同一持久值会在两个页面
        // 解析出不同源。
        for (var i = 0; i < 5; i++) {
          expect(resolveMediaSourceId(sources, 'beta'), 'beta');
        }
      },
    );

    test('always returns an id present in the source list when non-empty', () {
      const candidates = <String?>[null, '', 'alpha', 'beta', 'ghost', 'ALPHA'];

      for (final persisted in candidates) {
        final resolved = resolveMediaSourceId(sources, persisted);
        expect(
          sources.map((s) => s.id),
          contains(resolved),
          reason: 'resolved id must come from the list',
        );
      }
    });
  });

  group('defaultMediaSources', () {
    test('exposes bilibili then youtube', () {
      expect(defaultMediaSources.map((s) => s.id).toList(), [
        'bilibili',
        'youtube',
      ]);
    });

    test('holds distinct instances so each source owns its own client', () {
      // 同 id 的两个实例意味着两个网络客户端，dispose 只关掉其中一个。
      final ids = defaultMediaSources.map((s) => s.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('creates real Bili and YouTube implementations', () {
      expect(defaultMediaSources.first, isA<Bili>());
      expect(defaultMediaSources.last, isA<YouTube>());
    });

    test('is non-empty so the first-source fallback resolves', () {
      // 解析点约定空清单回退空标识；默认清单为空会让首屏 sourceId 为空。
      expect(defaultMediaSources, isNotEmpty);
      expect(resolveMediaSourceId(defaultMediaSources, null), 'bilibili');
    });
  });
}
