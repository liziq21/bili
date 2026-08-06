import 'package:multiple_result/multiple_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

extension ResultToAsyncValueX<S, E extends Object> on Result<S, E> {
  AsyncValue<S> toAsyncValue() {
    return when(
      (success) => AsyncData(success),
      (error) => AsyncError(error, StackTrace.current),
    );
  }
}
