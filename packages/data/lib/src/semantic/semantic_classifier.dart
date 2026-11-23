import 'package:model/model.dart';

/// Narrow semantic classification port.
///
/// Implementations may wrap a decision model or SLM, but they must not receive
/// credentials and must not be used for IDs, URLs, counts, or pagination.
abstract interface class SemanticClassifier() {
  Future<Result<String, Exception>> classify({
    required String text,
    required Set<String> labels,
  });
}

/// Deterministic keyword fallback for narrow classification.
///
/// This is intentionally simple: it is a safe fallback when no model is
/// available, and a baseline for model evaluation.
final class const KeywordSemanticClassifier({
  final Map<String, List<String>> keywords = const {},
}) implements SemanticClassifier {
  @override
  Future<Result<String, Exception>> classify({
    required String text,
    required Set<String> labels,
  }) async {
    final input = text.trim();
    if (input.isEmpty) {
      return Result.error(Exception('text must not be empty'));
    }
    if (labels.isEmpty) {
      return Result.error(Exception('labels must not be empty'));
    }

    final normalized = input.toLowerCase();
    String? bestLabel;
    var bestScore = 0;
    for (final label in labels.toList()..sort()) {
      final terms = keywords[label] ?? [label];
      final score = terms
          .where((term) => normalized.contains(term.toLowerCase()))
          .length;
      if (score > bestScore) {
        bestScore = score;
        bestLabel = label;
      }
    }

    if (bestLabel == null) {
      return Result.error(Exception('no label matched'));
    }
    return Result.success(bestLabel);
  }
}

/// Validates a primary classifier's label and falls back on any failure.
///
/// A model-backed primary must still be constrained to [labels]. This wrapper
/// enforces the allowlist, handles timeouts/exceptions, and keeps a deterministic
/// fallback path available.
final class const ValidatedSemanticClassifier({
  required final SemanticClassifier primary,
  required final SemanticClassifier fallback,
  final int maxTextLength = 2000,
}) implements SemanticClassifier {
  @override
  Future<Result<String, Exception>> classify({
    required String text,
    required Set<String> labels,
  }) async {
    final input = text.trim();
    if (input.isEmpty) {
      return Result.error(Exception('text must not be empty'));
    }
    if (labels.isEmpty) {
      return Result.error(Exception('labels must not be empty'));
    }
    if (input.length > maxTextLength) {
      return fallback.classify(text: input, labels: labels);
    }

    try {
      final result = await primary.classify(text: input, labels: labels);
      final valid = switch (result) {
        Success(:final success) => labels.contains(success),
        _ => false,
      };
      if (valid) return result;
      return await fallback.classify(text: input, labels: labels);
    } catch (_) {
      return fallback.classify(text: input, labels: labels);
    }
  }
}
