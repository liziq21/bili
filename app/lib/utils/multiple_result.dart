import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multiple_result/multiple_result.dart';

/// 将 [Result] 结果对象转换为 Riverpod 的 [AsyncValue]
extension ResultToAsyncValueX<S, E extends Object> on Result<S, E> {
  /// 将成功的 [Result] 转换为 [AsyncData]，失败的转换为 [AsyncError]
  AsyncValue<S> toAsyncValue() {
    return when(
      (success) => AsyncData(success),
      (error) => AsyncError(error, StackTrace.current),
    );
  }
}
