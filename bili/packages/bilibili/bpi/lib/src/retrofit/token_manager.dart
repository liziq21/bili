import 'dart:async';
import 'dart:convert';

import '../model/token_model.dart';
import 'token_storage.dart';

class TokenManager({final TokenStorage? storage}) {
  final Map<String, ApiToken> _memoryTokens = {};
  final Map<String, Completer<String>> _refreshLocks = {};

  String? getRefreshToken(String key) => _memoryTokens[key]?.refreshToken;
  Future<void> deleteToken(String key) async {
    _memoryTokens.remove(key);
    _refreshLocks.remove(key);
    await storage?.deleteToken(key);
  }

  Future<String?> getAccessToken(String key) async {
    var token = _memoryTokens[key];

    if (token == null && storage != null) {
      final apiTokenStr = await storage!.loadToken(key);
      if (apiTokenStr != null) {
        final jsonMap = json.decode(apiTokenStr) as Map<String, dynamic>;
        token = ApiToken.fromJson(jsonMap);
        _memoryTokens[key] = token;
      }
    }

    if (token != null && !token.isExpired) {
      return token.accessToken;
    }
    return null;
  }

  Future<void> updateToken(String key, ApiToken newToken) async {
    _memoryTokens[key] = newToken;
    if (storage != null) {
      await storage!.saveToken(key, json.encode(newToken.toJson()));
    }
  }

  Future<String> getOrRefreshWbiKey({
    required String key,
    required Future<String> Function() fetcher,
  }) async {
    final cachedToken = await getAccessToken(key);
    if (cachedToken != null) return cachedToken;

    final existingLock = _refreshLocks[key];
    if (existingLock != null) {
      return existingLock.future;
    }

    final completer = Completer<String>();
    _refreshLocks[key] = completer;

    try {
      final freshKey = await fetcher();
      await updateToken(
        key,
        ApiToken(
          accessToken: freshKey,
          expiresAt: DateTime.now().add(const Duration(days: 1)),
        ),
      );
      completer.complete(freshKey);
      return freshKey;
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      _refreshLocks.remove(key);
    }
  }
}
