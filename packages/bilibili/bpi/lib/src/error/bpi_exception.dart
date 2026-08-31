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
    String message, {
    required int biliCode,
    Uri? uri,
    int? statusCode,
    Object? cause,
  }) : super(
         message,
         biliCode: biliCode,
         uri: uri,
         statusCode: statusCode,
         cause: cause,
       );
}

final class BpiHttpException extends BpiException {
  const BpiHttpException(
    String message, {
    required int statusCode,
    Uri? uri,
    Object? cause,
  }) : super(message, statusCode: statusCode, uri: uri, cause: cause);
}

final class TokenException extends BpiException {
  const TokenException(super.message, {super.cause});
}
