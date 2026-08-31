class ApiToken({
  required final String accessToken,
  final String? refreshToken,
  required final DateTime expiresAt,
}) {
  bool get isExpired => isExpiredAt(DateTime.now());

  bool isExpiredAt(DateTime now) =>
      now.isAfter(expiresAt.subtract(const Duration(minutes: 5)));

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'expires_at': expiresAt.toIso8601String(),
  };

  factory ApiToken.fromJson(Map<String, dynamic> json) {
    final accessToken = json['access_token'];
    final expiresAt = json['expires_at'];
    if (accessToken is! String || expiresAt is! String) {
      throw const FormatException(
        'A token must contain access_token and expires_at strings.',
      );
    }

    return ApiToken(
      accessToken: accessToken,
      refreshToken: json['refresh_token'] as String?,
      expiresAt: DateTime.parse(expiresAt),
    );
  }
}
