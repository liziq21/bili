sealed class Result<T> {
  const Result();

  const factory Result.ok(T value) = Ok._;
  const factory Result.error(Exception error) = Error._;
}

extension ResultX<T> on Result<T> {
  Result<R> map<R>(R Function(T) transform) {
    return switch (this) {
      Ok(:final value) => .ok(transform(value)),
      Error(:final error) => .error(error),
    };
  }

  bool get isOk => this is Ok<T>;

  bool get isError => this is Error<T>;
}

extension ResultFutureX<T> on Future<T> {
  Future<Result<T>> toResult() async {
    try {
      final value = await this;
      return Result.ok(value);
    } catch (e) {
      return Result.error(Exception('$e'));
    }
  }
}

final class Ok<T> extends Result<T> {
  const Ok._(this.value);

  final T value;

  @override
  String toString() => 'Result<$T>.ok($value)';
}

final class Error<T> extends Result<T> {
  const Error._(this.error);

  final Exception error;

  @override
  String toString() => 'Result<$T>.error($error)';
}

