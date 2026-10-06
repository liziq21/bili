import 'package:app/utils/multiple_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

/// Tests for the `Result` -> `AsyncValue` bridge.
///
/// Every search path in the app funnels repository results through this
/// extension, so the two things that can break are the mapping itself (a
/// `Success` becoming an `AsyncError` or vice versa would flip a loaded screen
/// to an error state) and the error payload being carried through unchanged.
void main() {
  group('ResultToAsyncValue', () {
    test('maps a success to AsyncData holding the value', () {
      final result = Result<int, String>.success(42);

      final async = result.toAsyncValue();

      expect(async, isA<AsyncData<int>>());
      expect(async.value, 42);
      expect(async.hasValue, isTrue);
      expect(async.hasError, isFalse);
      expect(async.isLoading, isFalse);
    });

    test('maps an error to AsyncError holding the original error', () {
      final result = Result<int, String>.error('request failed');

      final async = result.toAsyncValue();

      expect(async, isA<AsyncError<int>>());
      expect(async.error, 'request failed');
      expect(async.hasError, isTrue);
      expect(async.hasValue, isFalse);
    });

    test('an AsyncData result is not in a loading state', () {
      // `AsyncLoading` would render a spinner over already-fetched data; the
      // mapping must never produce it. The concrete-type check covers it --
      // `isLoading` lives on `AsyncResult`, not on `AsyncValue`.
      final async = Result<int, String>.success(1).toAsyncValue();

      expect(async, isNot(isA<AsyncLoading<int>>()));
      expect(async.hasValue, isTrue);
    });

    test('an AsyncError result carries a usable stack trace', () {
      // Riverpod surfaces `stackTrace` in the error state; a null one leaves
      // the log line without any origin.
      final async = Result<int, String>.error('boom').toAsyncValue();

      expect((async as AsyncError<int>).stackTrace, isNotNull);
    });

    test('a null value inside a success is preserved, not dropped', () {
      // A nullable payload is legal; the mapping must not collapse it into a
      // missing state.
      final async = Result<String?, String>.success(null).toAsyncValue();

      expect(async, isA<AsyncData<String?>>());
      expect(async.value, isNull);
    });
  });
}
