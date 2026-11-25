import '../error/bpi_exception.dart';

/// 风控/限流响应：HTTP 412、`code: -352`（风控校验失败），以及 `data` 只有
/// `v_voucher` 的 GAIA 挑战。三者都是「源侧拒绝服务」，不是网络故障，稍后重
/// 试通常能恢复。
const int biliRiskControlCode = -352;

/// HTTP 412 Precondition Failed，B 站用它表示风控拦截。
const int biliRiskControlStatusCode = 412;

/// `data` 只有 `v_voucher` 时是 GAIA 风控挑战，而不是业务数据。
bool isBiliRiskControlChallenge(Map<String, dynamic> data) =>
    data.containsKey('v_voucher') && !data.containsKey('result');

/// 业务码本身是否表示风控拒绝。
bool isBiliRiskControlCode(int? code) => code == biliRiskControlCode;

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
    if (isBiliRiskControlCode(code)) {
      throw BiliRiskControlException(
        message ?? 'Bilibili risk-control rejection.',
        biliCode: code,
      );
    }
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

    if (isBiliRiskControlChallenge(dataMap)) {
      throw BiliRiskControlException(
        'Bilibili answered with a risk-control challenge instead of data.',
        biliCode: code,
      );
    }

    try {
      return .ok(code: code, data: fromJsonT(dataMap));
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
