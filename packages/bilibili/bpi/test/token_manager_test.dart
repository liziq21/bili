import 'package:bpi/src/model/token_model.dart';
import 'package:bpi/src/retrofit/token_manager.dart';
import 'package:bpi/src/retrofit/token_storage.dart';
import 'package:test/test.dart';

final class MemoryTokenStorage implements TokenStorage {
  final Map<String, String> values = {};

  @override
  Future<void> deleteToken(String key) async {
    values.remove(key);
  }

  @override
  Future<String?> loadToken(String key) async => values[key];

  @override
  Future<void> saveToken(String key, String token) async {
    values[key] = token;
  }
}

void main() {
  final now = DateTime(2026, 8, 30, 12);

  test('refreshes an expired token and persists the new key', () async {
    final storage = MemoryTokenStorage();
    final manager = TokenManager(storage: storage, clock: () => now);
    await manager.updateToken(
      'wbi',
      ApiToken(
        accessToken: 'old',
        expiresAt: now.subtract(const Duration(minutes: 1)),
      ),
    );

    var fetchCount = 0;
    final key = await manager.getOrRefreshWbiKey(
      key: 'wbi',
      fetcher: () async {
        fetchCount++;
        return 'fresh';
      },
    );

    expect(key, 'fresh');
    expect(fetchCount, 1);
    expect(await manager.getAccessToken('wbi'), 'fresh');
  });

  test('deduplicates concurrent refreshes', () async {
    final manager = TokenManager(clock: () => now);
    var fetchCount = 0;

    Future<String> fetcher() async {
      fetchCount++;
      await Future<void>.delayed(Duration.zero);
      return 'fresh';
    }

    final results = await Future.wait([
      manager.getOrRefreshWbiKey(key: 'wbi', fetcher: fetcher),
      manager.getOrRefreshWbiKey(key: 'wbi', fetcher: fetcher),
    ]);

    expect(results, ['fresh', 'fresh']);
    expect(fetchCount, 1);
  });

  test('invalidates a token without removing an active refresh lock', () async {
    final manager = TokenManager(clock: () => now);
    final completer = Future<String>.delayed(
      const Duration(milliseconds: 1),
      () => 'fresh',
    );

    final first = manager.getOrRefreshWbiKey(
      key: 'wbi',
      fetcher: () => completer,
    );
    await manager.deleteToken('wbi');

    expect(await first, 'fresh');
  });
}
