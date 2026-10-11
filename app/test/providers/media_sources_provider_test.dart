import 'package:app/providers/media_sources_provider.dart';
import 'package:bilibili/bilibili.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtube/youtube.dart';

void main() {
  group('defaultMediaSources', () {
    test('exposes bilibili then youtube', () {
      expect(defaultMediaSources.map((source) => source.id).toList(), [
        'bilibili',
        'youtube',
      ]);
    });

    test('holds distinct instances so each source owns its own client', () {
      final ids = defaultMediaSources.map((source) => source.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('creates real Bili and YouTube implementations', () {
      expect(defaultMediaSources.first, isA<Bili>());
      expect(defaultMediaSources.last, isA<YouTube>());
    });

    test('is non-empty for the default source fallback', () {
      expect(defaultMediaSources, isNotEmpty);
    });
  });
}
