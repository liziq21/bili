class ApiToken({
  required final String accessToken,
  final String? refreshToken,
  required final DateTime expiresAt,
}) {
  bool get isExpired {
    return DateTime.now().isAfter(
      expiresAt.subtract(const Duration(minutes: 5)),
    );
  }

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'expires_at': expiresAt.toIso8601String(),
  };

  factory ApiToken.fromJson(Map<String, dynamic> json) => ApiToken(
    accessToken: json['access_token'],
    refreshToken: json['refresh_token'],
    expiresAt: DateTime.parse(json['expires_at']),
  );
}
