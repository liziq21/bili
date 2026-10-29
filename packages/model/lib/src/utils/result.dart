/// Result 类型已迁移至 [multiple_result] 包。
///
/// 本文件重新导出 [multiple_result] 的 Result/Success/Error，
/// 并保留 [ResultFutureX.toResult] 扩展作为便利方法。
library;

import 'package:multiple_result/multiple_result.dart';
export 'package:multiple_result/multiple_result.dart';

/// 扩展 [Future] 以将其执行过程转换为 [Result]。
extension ResultFutureX<T> on Future<T> {
  /// 捕获 Future 执行过程中的异常并封装为 [Result]。
  Future<Result<T, Exception>> toResult() async {
    try {
      final value = await this;
      return Result.success(value);
    } catch (e, s) {
      return Result.error(Exception('$e\n$s'));
    }
  }
}
