import '../error/bpi_exception.dart';

sealed class const ApiResult<T>() {
  const factory ApiResult.error({required int code, String? message}) = Error._;
  const factory ApiResult.ok({required int code, required T data}) = Ok._;

  factory ApiResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final code = switch (json['code']) {
      num value => value.toInt(),
      String value => int.tryParse(value),
      _ => null,
    };
    if (code == null) {
      throw const BpiSerializationException(
        'Bilibili response is missing a numeric code.',
      );
    }

    final message = json['message']?.toString();
    if (code != 0) {
      return .error(code: code, message: message);
    }

    final rawData = json['data'] ?? json['result'];
    final Map<String, dynamic> dataMap;
    if (rawData is Map) {
      dataMap = Map<String, dynamic>.from(rawData);
    } else if (rawData is List) {
      dataMap = {'items': rawData, 'list': rawData};
    } else {
      throw BpiSerializationException(
        'Successful Bilibili response is missing an object data/result field.',
        biliCode: code,
      );
    }

    try {
      return .ok(
        code: code,
        data: fromJsonT(dataMap),
      );
    } on BpiException {
      rethrow;
    } on Object catch (error) {
      throw BpiSerializationException(
        'Failed to decode Bilibili response data.',
        biliCode: code,
        cause: error,
      );
    }
  }
}

final class const Error<T>._({required final int code, final String? message})
    extends ApiResult<T> {
  @override
  String toString() => 'ApiResult<$T>.error(code: $code, message : $message)';
}

final class const Ok<T>._({required final int code, required final T data})
    extends ApiResult<T> {
  @override
  String toString() => 'ApiResult<$T>.ok($data)';
}
