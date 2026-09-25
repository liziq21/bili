/// Base class for errors exposed by the ypi package.
sealed class YpiException implements Exception {
  const YpiException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// The underlying HTTP client could not complete the request.
final class YpiNetworkException extends YpiException {
  const YpiNetworkException(super.message);
}

/// The server returned a non-successful HTTP status.
final class YpiHttpException extends YpiException {
  const YpiHttpException(this.statusCode)
    : super('YouTube API returned HTTP $statusCode');

  final int statusCode;
}

/// The InnerTube response contained an API error.
final class YpiInnerTubeException extends YpiException {
  const YpiInnerTubeException({this.code, this.continuation, this.reason})
    : super(
        'YouTube InnerTube error'
        '${code == null ? '' : ' (code: $code)'}'
        '${reason == null ? '' : ': $reason'}',
      );

  final int? code;
  final String? continuation;
  final String? reason;
}

/// The response body was empty or could not be decoded.
final class YpiJsonException extends YpiException {
  const YpiJsonException(super.message);
}

/// The supplied client configuration cannot form a valid request context.
final class YpiClientContextException extends YpiException {
  const YpiClientContextException(super.message);
}
