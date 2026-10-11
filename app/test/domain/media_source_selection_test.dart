import 'package:app/domain/media_source_selection.dart';
import 'package:data/data.dart';
import 'package:test/test.dart';

/// 仅提供 id 的假数据源，用于构造任意清单。
class _FakeSource(@override final String id) extends MediaSource {
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
      expect(resolveMediaSourceId(sources, 'removed-source'), 'alpha');
    });

    test('returns an empty id for an empty list instead of throwing', () {
      expect(resolveMediaSourceId(const <MediaSource>[], null), '');
      expect(resolveMediaSourceId(const <MediaSource>[], 'alpha'), '');
    });

    test('an empty persisted value falls back to the first id', () {
      expect(resolveMediaSourceId(sources, ''), 'alpha');
    });

    test('matches ids exactly', () {
      expect(resolveMediaSourceId(sources, 'ALPHA'), 'alpha');
    });

    test('produces the same result for a single-source list', () {
      final single = <MediaSource>[_FakeSource('solo')];

      expect(resolveMediaSourceId(single, 'solo'), 'solo');
      expect(resolveMediaSourceId(single, null), 'solo');
      expect(resolveMediaSourceId(single, 'other'), 'solo');
    });

    test('always returns an id present in the source list when non-empty', () {
      const candidates = <String?>[null, '', 'alpha', 'beta', 'ghost', 'ALPHA'];

      for (final persisted in candidates) {
        final resolved = resolveMediaSourceId(sources, persisted);
        expect(
          sources.map((source) => source.id),
          contains(resolved),
          reason: 'resolved id must come from the list',
        );
      }
    });
  });
}
