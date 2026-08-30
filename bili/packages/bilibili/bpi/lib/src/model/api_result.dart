sealed class const ApiResult<T>() {
  const factory ApiResult.error({required int code, String? message}) = Error._;
  const factory ApiResult.ok({required int code, required T data}) = Ok._;

  factory ApiResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final code = json['code'] as int;
    final message = json['message'] as String?;

    if (code != 0 && code != 3 ||
        (message != null &&
            message.isNotEmpty &&
            message != '0' &&
            message != 'OK')) {
      return .error(code: code, message: message ?? 'Not message');
    }

    final data = (json['data'] ?? json['result']) as Map<String, dynamic>;
    return .ok(code: code, data: fromJsonT(data));
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

// sealed class const ApiResult<T>() {
//   const factory ApiResult.ok({required int code, required T data}) = Ok._;
//
//   const factory ApiResult.error({required int code, String? message}) = Error._;
//
//   factory ApiResult.fromJson(
//     Map<String, dynamic> json,
//     T Function(Map<String, dynamic>) fromJsonT,
//   ) {
//     final code = json['code'] as int;
//     final message = json['message'] as String?;
//
//     if (code != 0 && code != 3 ||
//         (message != null && message.isNotEmpty && message != '0')) {
//       return ApiResultError(code: code, message: message ?? 'Not message');
//     }
//
//     final data = (json['data'] ?? json['result']) as Map<String, dynamic>;
//     return ApiResultOk(code: code, data: fromJsonT(data));
//   }
// }
//
// class const OK<T>._({required final int code, required final T data}) extends ApiResult<T>;
