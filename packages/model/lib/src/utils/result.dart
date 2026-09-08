final class Error<T> extends Result<T> {
  const Error._(this.error) : super._();
  final Exception error;

  @override
  String toString() => 'Result<$T>.error($error)';
}

final class Ok<T> extends Result<T> {
  const Ok._(this.value) : super._();
  final T value;

  @override
  String toString() => 'Result<$T>.ok($value)';
}

sealed class Result<T> {
  const Result._();
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
      Ok(:final value) => Result.ok(transform(value)),
      Error(:final error) => Result.error(error),
    };
  }
}
