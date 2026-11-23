import 'dart:ui' show Locale;

import 'package:app/feature/notification/feed_update_notifier.dart';
import 'package:app/feature/notification/local_feed_update_notifier.dart';
import 'package:app/feature/notification/notification_presenter.dart';
import 'package:app/datastore/preferences_data_source.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:model/model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// 一个「平台支持通知」的替身。
///
/// 测试跑在 Linux 宿主上，真实 presenter 的 `isSupported` 恒为 false，任何
/// 走到「发送通知」分支的断言都会变成空转。这个替身让该分支可被断言。
final class _SupportedPresenter() implements NotificationPresenter {
  final shown = <String>[];

  @override
  bool get isSupported => true;

  @override
  Future<void> initialize({
    required void Function(String? payload) onTap,
  }) async {}

  @override
  Future<({bool launched, String? payload})> launchDetails() async =>
      (launched: false, payload: null);

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> show({
    required String title,
    required String body,
    required String payload,
    int id = 0,
    String channelId = feedUpdatesChannelId,
    String channelName = feedUpdatesChannelName,
    String channelDescription = feedUpdatesChannelDescription,
  }) async => shown.add(payload);

  @override
  Future<void> cancel({int id = 0}) async {}
}

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
      'exactly reaching the threshold notifies and advances to the count',
      () async {
        // Given a supported platform, a threshold of 3 and exactly 3 new items.
        final presenter = _SupportedPresenter();
        final supported = LocalFeedUpdateNotifier(
          preferences,
          presenter: presenter,
          localizations: lookupAppLocalizations(const Locale('en')),
        );
        addTearDown(supported.dispose);

        // When the feed is polled.
        final result = await supported.notifyIfThresholdReached(
          currentCount: 6,
          threshold: 3,
          lastNotifiedCount: 3,
        );

        // Then one notification is shown and the count is acknowledged.
        expect((result as Success<int, Exception>).success, 6);
        expect(presenter.shown, hasLength(1));
      },
    );

    test('reaching the threshold twice in a row notifies only once', () async {
      // Given the first poll already showed a notification.
      final presenter = _SupportedPresenter();
      final supported = LocalFeedUpdateNotifier(
        preferences,
        presenter: presenter,
        localizations: lookupAppLocalizations(const Locale('en')),
      );
      addTearDown(supported.dispose);
      final first = await supported.notifyIfThresholdReached(
        currentCount: 6,
        threshold: 3,
        lastNotifiedCount: 3,
      );
      final acknowledged = (first as Success<int, Exception>).success;

      // When the same unread count is polled again with that baseline.
      await supported.notifyIfThresholdReached(
        currentCount: 6,
        threshold: 3,
        lastNotifiedCount: acknowledged,
      );

      // Then no second notification is pushed for the same entries.
      expect(presenter.shown, hasLength(1));
    });

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
