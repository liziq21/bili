sealed class BpiException implements Exception {
  const BpiException(
    this.message, {
    this.uri,
    this.statusCode,
    this.biliCode,
    this.cause,
  });

  final String message;
  final Uri? uri;
  final int? statusCode;
  final int? biliCode;
  final Object? cause;

  /// This error bound to [uri], keeping the current URI when it has one.
  ///
  /// Converters raise errors without any request context, so the network layer
  /// completes them once, at the only place that still holds the request.
  BpiException withUri(Uri uri) {
    if (this.uri != null) return this;
    return switch (this) {
      BiliApiException e => BiliApiException(
        e.message,
        biliCode: e.biliCode,
        uri: uri,
        statusCode: e.statusCode,
        cause: e.cause,
      ),
      BiliRiskControlException e => BiliRiskControlException(
        e.message,
        uri: uri,
        statusCode: e.statusCode,
        biliCode: e.biliCode,
        cause: e.cause,
      ),
      BpiHttpException e => BpiHttpException(
        e.message,
        statusCode: e.statusCode,
        uri: uri,
        cause: e.cause,
      ),
      BpiNetworkException e => BpiNetworkException(
        e.message,
        uri: uri,
        cause: e.cause,
      ),
      BpiSerializationException e => BpiSerializationException(
        e.message,
        uri: uri,
        statusCode: e.statusCode,
        biliCode: e.biliCode,
        cause: e.cause,
      ),
      WbiException e => WbiException(
        e.message,
        uri: uri,
        statusCode: e.statusCode,
        biliCode: e.biliCode,
        cause: e.cause,
      ),
      // Token failures happen before any request exists.
      TokenException() => this,
    };
  }

  @override
  String toString() {
    final details = <String>[
      if (statusCode != null) 'statusCode=$statusCode',
      if (biliCode != null) 'biliCode=$biliCode',
      if (uri != null) 'uri=$uri',
    ];
    final suffix = details.isEmpty ? '' : ' (${details.join(', ')})';
    return '$runtimeType: $message$suffix';
  }
}

final class WbiException extends BpiException {
  const WbiException(
    super.message, {
    super.uri,
    super.statusCode,
    super.biliCode,
    super.cause,
  });
}

/// Bilibili answered with a GAIA risk-control challenge instead of data.
///
/// The envelope still carries `code: 0`, so this is not an API error and not a
/// decoding bug: `data` holds only `v_voucher`, which needs a captcha the
/// client cannot solve. The request is safe to retry later.
/// B 站以风控/限流为由拒绝了这次请求，稍后重试可能成功。
///
/// 覆盖三种实测形态：HTTP 412、业务码 `-352`，以及 `code: 0` 但 `data` 只有
/// `v_voucher` 的 GAIA 挑战。前两种带 [BpiException.statusCode]，后两种带
/// [BpiException.biliCode]。
final class BiliRiskControlException extends BpiException {
  const BiliRiskControlException(
    super.message, {
    super.uri,
    super.statusCode,
    super.biliCode,
    super.cause,
  });
}

final class BpiSerializationException extends BpiException {
  const BpiSerializationException(
    super.message, {
    super.uri,
    super.statusCode,
    super.biliCode,
    super.cause,
  });
}

final class BiliApiException extends BpiException {
  const BiliApiException(
    super.message, {
    required super.biliCode,
    super.uri,
    super.statusCode,
    super.cause,
  });
}

final class BpiHttpException extends BpiException {
  const BpiHttpException(
    super.message, {
    required super.statusCode,
    super.uri,
    super.cause,
  });
}

final class BpiNetworkException extends BpiException {
  const BpiNetworkException(super.message, {super.uri, super.cause});
}

final class TokenException extends BpiException {
  const TokenException(super.message, {super.cause});
}
