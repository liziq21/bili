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
  ///
  /// 已经是 [Exception] 的错误按原对象返回：调用方要按类型区分失败原因
  /// （限流、风控等），把它串成字符串就会丢掉类型。只有非 [Exception] 的
  /// 抛出物才包成文本，并保留堆栈。
  Future<Result<T, Exception>> toResult() async {
    try {
      return Result.success(await this);
    } on Exception catch (error) {
      return Result.error(error);
    } on Object catch (error, stackTrace) {
      return Result.error(Exception('$error\n$stackTrace'));
    }
  }
}
