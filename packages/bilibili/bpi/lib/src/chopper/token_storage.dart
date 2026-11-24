abstract class TokenStorage {
  Future<void> saveToken(String key, String token);
  Future<String?> loadToken(String key);
  Future<void> deleteToken(String key);
}
