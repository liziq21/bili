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

final class TokenException extends BpiException {
  const TokenException(super.message, {super.cause});
}
