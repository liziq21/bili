/// 表示异步或同步操作返回错误结果的 [Result] 子类
final class const Error<T>._(final Exception error) extends Result<T> {
  @override
  String toString() => 'Result<$T>.error($error)';
}

/// 表示异步或同步操作成功返回值的 [Result] 子类
final class const Ok<T>._(final T value) extends Result<T> {
  @override
  String toString() => 'Result<$T>.ok($value)';
}

/// 函数式错误处理的密封类型 [Result]
///
/// 封装操作成功 [Ok] 或失败 [Error] 两种状态，避免抛出未经处理的异常。
sealed class const Result<T>() {
  /// 构造失败的 [Result] 实例
  const factory error(Exception error) = Error._;

  /// 构造成功的 [Result] 实例
  const factory ok(T value) = Ok._;
}

/// 扩展 [Future] 以将其执行过程转换为 [Result]
extension ResultFutureX<T> on Future<T> {
  /// 捕获 Future 执行过程中的异常并封装为 [Result]
  Future<Result<T>> toResult() async {
    try {
      final value = await this;
      return Result.ok(value);
    } catch (e, s) {
      return Result.error(Exception('$e\n$s'));
    }
  }
}

/// [Result] 常用便利方法扩展
extension ResultX<T> on Result<T> {
  /// 当前结果是否为错误 [Error]
  bool get isError => this is Error<T>;

  /// 当前结果是否为成功 [Ok]
  bool get isOk => this is Ok<T>;

  /// 当结果为成功时，对内部值进行类型转换或映射处理
  Result<R> map<R>(R Function(T) transform) {
    return switch (this) {
      Ok(:final value) => .ok(transform(value)),
      Error(:final error) => .error(error),
    };
  }
}
