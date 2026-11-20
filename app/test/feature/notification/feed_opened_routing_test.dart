import 'dart:ui' show Locale;

import 'package:app/datastore/preferences_data_source.dart';
import 'package:app/feature/notification/local_feed_update_notifier.dart';
import 'package:app/feature/notification/notification_presenter.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:model/model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// 记录平台调用并允许手动触发点击 / 冷启动。
///
/// 点击回调的真实来源是平台通道，这里把 `onTap` 保存下来，测试直接调用它，
/// 覆盖「点击 → feedOpened」这条链路而不需要 Android 宿主。
final class _FakePresenter(final bool launchFromNotification)
    implements NotificationPresenter {
  void Function(String? payload)? onTap;
  final shown = <({String title, String body, String payload})>[];
  int initializeCalls = 0;

  @override
  bool get isSupported => true;

  @override
  Future<void> initialize({
    required void Function(String? payload) onTap,
  }) async {
    initializeCalls++;
    this.onTap = onTap;
  }

  @override
  Future<({bool launched, String? payload})> launchDetails() async => (
    launched: launchFromNotification,
    payload: launchFromNotification ? 'feed' : null,
  );

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> show({
    required String title,
    required String body,
    required String payload,
  }) async {
    shown.add((title: title, body: body, payload: payload));
  }
}

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  late PreferencesDataSource preferences;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    preferences = PreferencesDataSource(
      sharedPreferences: SharedPreferencesAsync(),
    );
  });

  tearDown(() => preferences.dispose());

  group('feedOpened tap routing', () {
    test('a tap while the app is running emits on feedOpened', () async {
      // Given a notifier whose platform channel is ready and a live listener.
      final presenter = _FakePresenter(false);
      final notifier = LocalFeedUpdateNotifier(
        preferences,
        presenter: presenter,
      );
      addTearDown(notifier.dispose);
      final events = <void>[];
      final subscription = notifier.feedOpened.listen(events.add);
      addTearDown(subscription.cancel);
      await notifier.initialize();

      // When the user taps the notification.
      presenter.onTap!('feed');
      await Future<void>.delayed(Duration.zero);

      // Then exactly one open request reached the listener.
      expect(events, hasLength(1));
    });

    test('a cold start launched by the notification emits to the listener '
        'that subscribes afterwards', () async {
      // Given the app was started by tapping the notification, so the tap
      // landed during initialize() before any listener existed.
      final presenter = _FakePresenter(true);
      final notifier = LocalFeedUpdateNotifier(
        preferences,
        presenter: presenter,
      );
      addTearDown(notifier.dispose);
      await notifier.initialize();

      // When the shell subscribes afterwards.
      final events = <void>[];
      final subscription = notifier.feedOpened.listen(events.add);
      addTearDown(subscription.cancel);
      await Future<void>.delayed(Duration.zero);

      // Then the buffered tap is delivered instead of being lost.
      expect(events, hasLength(1));
    });

    test('a normal start does not emit anything', () async {
      // Given the app was started normally, not from a notification.
      final presenter = _FakePresenter(false);
      final notifier = LocalFeedUpdateNotifier(
        preferences,
        presenter: presenter,
      );
      addTearDown(notifier.dispose);
      final events = <void>[];
      final subscription = notifier.feedOpened.listen(events.add);
      addTearDown(subscription.cancel);

      // When the notifier initializes.
      await notifier.initialize();
      await Future<void>.delayed(Duration.zero);

      // Then no navigation is requested.
      expect(events, isEmpty);
    });

    test('initialize registers the tap handler only once', () async {
      // Given a notifier that was already initialized.
      final presenter = _FakePresenter(false);
      final notifier = LocalFeedUpdateNotifier(
        preferences,
        presenter: presenter,
      );
      addTearDown(notifier.dispose);
      await notifier.initialize();

      // When initialize is called again (settings page + shell listener).
      await notifier.initialize();

      // Then the channel is created once, not on every call.
      expect(presenter.initializeCalls, 1);
    });

    test('a notification carries the feed payload', () async {
      // Given notifications are enabled with a threshold of 3.
      final presenter = _FakePresenter(false);
      final notifier = LocalFeedUpdateNotifier(
        preferences,
        presenter: presenter,
        localizations: l10n,
      );
      addTearDown(notifier.dispose);

      // When the feed grows past the threshold.
      final result = await notifier.notifyIfThresholdReached(
        currentCount: 5,
        threshold: 3,
        lastNotifiedCount: 0,
      );

      // Then the shown notification is tagged so its tap can route to feed,
      // and its copy comes from l10n rather than a hardcoded string.
      expect((result as Success<int, Exception>).success, 5);
      final shown = presenter.shown.single;
      expect(shown.payload, 'feed');
      expect(shown.title, l10n.feedUpdateNotificationTitle);
      expect(shown.body, l10n.feedUpdateNotificationBody(5));
    });
  });
}
