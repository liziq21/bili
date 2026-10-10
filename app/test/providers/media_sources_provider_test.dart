import 'dart:async';

import 'package:app/providers/media_sources_provider.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MediaSourceCatalog', () {
    test('contains source definitions without creating source instances', () {
      expect(defaultMediaSourceCatalog.definitions.map((source) => source.id), [
        'bilibili',
        'youtube',
      ]);
      expect(defaultMediaSourceCatalog.definitions, everyElement(isNotNull));
    });

    test('resolves canonical and case-insensitive source IDs', () {
      expect(defaultMediaSourceCatalog.find('bilibili')?.id, 'bilibili');
      expect(defaultMediaSourceCatalog.find(' YouTube ')?.id, 'youtube');
    });

    test('falls back to the first definition for stale persisted values', () {
      expect(
        defaultMediaSourceCatalog.resolvePersisted('removed')?.id,
        'bilibili',
      );
      expect(defaultMediaSourceCatalog.resolvePersisted(null)?.id, 'bilibili');
    });

    test('returns null when an empty catalog resolves a persisted value', () {
      final catalog = MediaSourceCatalog(const []);

      expect(catalog.resolvePersisted(null), isNull);
      expect(catalog.resolvePersisted('bilibili'), isNull);
    });

    test(
      'creates source instances only when a definition factory is called',
      () {
        final definition = defaultMediaSourceCatalog.definitions.first;
        final first = definition.create();
        final second = definition.create();

        expect(first, isA<MediaSource>());
        expect(identical(first, second), isFalse);
        unawaited(first.close());
        unawaited(second.close());
      },
    );
  });

  group('normalizeMediaSourceId', () {
    test('trims and lowercases external source IDs', () {
      expect(normalizeMediaSourceId(' YouTube '), 'youtube');
    });
  });
}
