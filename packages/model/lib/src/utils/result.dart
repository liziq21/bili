final class const Error<T>._(final Exception error) extends Result<T> {
  @override
  String toString() => 'Result<$T>.error($error)';
}

final class const Ok<T>._(final T value) extends Result<T> {
  @override
  String toString() => 'Result<$T>.ok($value)';
}

sealed class const Result<T>() {
  const factory Result.error(Exception error) = Error._;
  const factory Result.ok(T value) = Ok._;
}

extension ResultFutureX<T> on Future<T> {
  Future<Result<T>> toResult() async {
    try {
      final value = await this;
      return Result.ok(value);
    } catch (e, s) {
      return Result.error(Exception('$e\n$s'));
    }
  }
}

extension ResultX<T> on Result<T> {
  bool get isError => this is Error<T>;

  bool get isOk => this is Ok<T>;

  Result<R> map<R>(R Function(T) transform) {
    return switch (this) {
      Ok(:final value) => .ok(transform(value)),
      Error(:final error) => .error(error),
    };
  }
}
