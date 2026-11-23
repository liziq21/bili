import 'package:data/data.dart';
import 'package:model/model.dart';
import 'package:test/test.dart';

final class _FakeClassifier(
  final Result<String, Exception>? result, {
  final bool throws = false,
}) implements SemanticClassifier {
  var calls = 0;

  @override
  Future<Result<String, Exception>> classify({
    required String text,
    required Set<String> labels,
  }) async {
    calls++;
    if (throws) throw StateError('model unavailable');
    return result ?? Result.error(Exception('no result'));
  }
}

void main() {
  const labels = {'video', 'music'};
  final fallback = KeywordSemanticClassifier(
    keywords: const {
      'video': ['video', 'watch'],
      'music': ['music', 'song'],
    },
  );

  test('keyword fallback picks the best matching label', () async {
    final result = await fallback.classify(
      text: 'watch this video',
      labels: labels,
    );

    expect(result, isA<Success<String, Exception>>());
    expect((result as Success<String, Exception>).success, 'video');
  });

  test(
    'validated classifier accepts a primary label in the allowlist',
    () async {
      final primary = _FakeClassifier(Result.success('music'));
      final classifier = ValidatedSemanticClassifier(
        primary: primary,
        fallback: fallback,
      );

      final result = await classifier.classify(text: 'song', labels: labels);

      expect(result, isA<Success<String, Exception>>());
      expect((result as Success<String, Exception>).success, 'music');
      expect(primary.calls, 1);
    },
  );

  test(
    'validated classifier falls back when primary returns an unknown label',
    () async {
      final primary = _FakeClassifier(Result.success('unknown'));
      final classifier = ValidatedSemanticClassifier(
        primary: primary,
        fallback: fallback,
      );

      final result = await classifier.classify(text: 'watch', labels: labels);

      expect(result, isA<Success<String, Exception>>());
      expect((result as Success<String, Exception>).success, 'video');
    },
  );

  test('validated classifier falls back when primary throws', () async {
    final primary = _FakeClassifier(null, throws: true);
    final classifier = ValidatedSemanticClassifier(
      primary: primary,
      fallback: fallback,
    );

    final result = await classifier.classify(text: 'song', labels: labels);

    expect(result, isA<Success<String, Exception>>());
    expect((result as Success<String, Exception>).success, 'music');
  });

  test('rejects empty text and labels before calling the primary', () async {
    final primary = _FakeClassifier(Result.success('video'));
    final classifier = ValidatedSemanticClassifier(
      primary: primary,
      fallback: fallback,
    );

    expect(
      await classifier.classify(text: ' ', labels: labels),
      isA<Error<String, Exception>>(),
    );
    expect(
      await classifier.classify(text: 'video', labels: const {}),
      isA<Error<String, Exception>>(),
    );
    expect(primary.calls, 0);
  });

  test('routes oversized input to the fallback', () async {
    final primary = _FakeClassifier(Result.success('video'));
    final classifier = ValidatedSemanticClassifier(
      primary: primary,
      fallback: fallback,
      maxTextLength: 5,
    );

    final result = await classifier.classify(
      text: 'watch a long video',
      labels: labels,
    );

    expect(result, isA<Success<String, Exception>>());
    expect((result as Success<String, Exception>).success, 'video');
    expect(primary.calls, 0);
  });
}
