import 'dart:async';
import 'dart:convert';

import '../model/token_model.dart';
import '../error/bpi_exception.dart';
import 'token_storage.dart';

class TokenManager {
  TokenManager({this.storage, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final TokenStorage? storage;
  final DateTime Function() _clock;
  final Map<String, ApiToken> _memoryTokens = {};
  final Map<String, Completer<String>> _refreshLocks = {};

  String? getRefreshToken(String key) => _memoryTokens[key]?.refreshToken;
  Future<void> deleteToken(String key) async {
    _memoryTokens.remove(key);
    await storage?.deleteToken(key);
  }

  Future<String?> getAccessToken(String key) async {
    var token = _memoryTokens[key];

    if (token == null && storage != null) {
      late final String? apiTokenStr;
      try {
        apiTokenStr = await storage!.loadToken(key);
      } on Object catch (error) {
        throw TokenException('Failed to load token "$key".', cause: error);
      }
      if (apiTokenStr != null) {
        try {
          final decoded = json.decode(apiTokenStr);
          if (decoded is! Map) {
            throw const FormatException('Token JSON must be an object.');
          }
          token = ApiToken.fromJson(Map<String, dynamic>.from(decoded));
        } on Object catch (error) {
          throw TokenException('Stored token "$key" is invalid.', cause: error);
        }
        _memoryTokens[key] = token;
      }
    }

    if (token != null && !token.isExpiredAt(_clock())) {
      return token.accessToken;
    }
    return null;
  }

  Future<void> updateToken(String key, ApiToken newToken) async {
    _memoryTokens[key] = newToken;
    if (storage != null) {
      try {
        await storage!.saveToken(key, json.encode(newToken.toJson()));
      } on Object catch (error) {
        throw TokenException('Failed to save token "$key".', cause: error);
      }
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
          expiresAt: _clock().add(const Duration(days: 1)),
        ),
      );
      completer.complete(freshKey);
      return freshKey;
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      if (identical(_refreshLocks[key], completer)) {
        _refreshLocks.remove(key);
      }
    }
  }
}
