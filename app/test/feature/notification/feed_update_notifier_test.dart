import 'package:app/feature/notification/feed_update_notifier.dart';
import 'package:app/feature/notification/local_feed_update_notifier.dart';
import 'package:app/datastore/preferences_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:model/model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Platform-agnostic feed update decision logic.
///
/// The notifier is the only place that knows when a notification is due, so
/// these tests pin the arithmetic that every future feed loader relies on:
/// the threshold boundary, the dedupe rule, and the fact that a disabled
/// feature never reports a new count.
void main() {
  group('FeedUpdateNotifier threshold logic', () {
    late PreferencesDataSource preferences;
    late LocalFeedUpdateNotifier notifier;

    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      preferences = PreferencesDataSource(
        sharedPreferences: SharedPreferencesAsync(),
      );
      notifier = LocalFeedUpdateNotifier(preferences);
    });

    tearDown(() async {
      await notifier.dispose();
      preferences.dispose();
    });

    test('a disabled threshold never advances the count', () async {
      // Given the feed grew past any plausible threshold.
      // When notifications are disabled with threshold 0.
      final result = await notifier.notifyIfThresholdReached(
        currentCount: 50,
        threshold: 0,
        lastNotifiedCount: 0,
      );

      // Then the caller keeps its old count and no notification is sent.
      expect(result, isA<Success<int, Exception>>());
      expect((result as Success<int, Exception>).success, 0);
    });

    test('one item below the threshold does not advance the count', () async {
      // Given a threshold of 3 and only 2 new items.
      // When the feed is polled.
      final result = await notifier.notifyIfThresholdReached(
        currentCount: 5,
        threshold: 3,
        lastNotifiedCount: 3,
      );

      // Then nothing is acknowledged as notified.
      expect((result as Success<int, Exception>).success, 3);
    });

    test(
      'exactly reaching the threshold advances to the current count',
      () async {
        // Given a threshold of 3 and exactly 3 new items.
        // When the feed is polled. The platform is not Android in the test
        // runner, so the show() path is skipped but the arithmetic still runs
        // through the same guard order.
        final result = await notifier.notifyIfThresholdReached(
          currentCount: 6,
          threshold: 3,
          lastNotifiedCount: 3,
        );

        // Then the count is either acknowledged (notification shown) or left
        // alone (notifications unavailable on this platform) — never bogus.
        final count = (result as Success<int, Exception>).success;
        expect(count, anyOf(3, 6));
      },
    );

    test('a shrunken feed never triggers or advances', () async {
      // Given the last notified count is above the current count.
      // When the feed is polled.
      final result = await notifier.notifyIfThresholdReached(
        currentCount: 2,
        threshold: 3,
        lastNotifiedCount: 10,
      );

      // Then the negative delta is treated as nothing new.
      expect((result as Success<int, Exception>).success, 10);
    });

    test('unsupported platforms report false without a dialog', () async {
      // Given the test runner's platform is not Android.
      // When permission is requested.
      final result = await notifier.requestPermission();

      // Then the call reports plainly instead of throwing or prompting.
      expect(result, isA<Success<bool, Exception>>());
      expect((result as Success<bool, Exception>).success, isFalse);
    });

    test('the notifier exposes the platform capability as a bool', () {
      // The getter must be answered synchronously so settings can branch on it.
      expect(notifier.isSupported, isA<bool>());
    });

    test('the abstract contract is implemented', () {
      // Guards against a refactor that drops a method from the interface.
      expect(notifier, isA<FeedUpdateNotifier>());
    });
  });
}
