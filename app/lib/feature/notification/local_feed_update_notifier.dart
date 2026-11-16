import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:model/model.dart';

import '../../datastore/preferences_data_source.dart';
import 'feed_update_notifier.dart';

/// Android implementation of [FeedUpdateNotifier] backed by
/// `flutter_local_notifications`.
///
/// Every method is best effort: notification failures are reported as
/// [Error] results and never thrown, so a missing permission or a broken
/// platform channel cannot break the caller that polls the feed.
///
/// On platforms other than Android (and on web) [isSupported] is false and
/// all calls resolve without side effects.
final class LocalFeedUpdateNotifier(final PreferencesDataSource _preferences)
    implements FeedUpdateNotifier {
  static const _channelId = 'feed_updates';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  @override
  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<Result<void, Exception>> initialize() async {
    if (!isSupported || _initialized) {
      return const Result.success(null);
    }

    try {
      // Channel creation does not prompt; the dialog is triggered explicitly
      // via [requestPermission] when the user opts in from settings.
      await _android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          'Feed updates',
          description: 'Notifies about new items in your feed',
          importance: Importance.high,
        ),
      );
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      _initialized = true;
      return const Result.success(null);
    } on Object catch (error, stackTrace) {
      return Result.error(
        Exception('Failed to initialize notifications: $error\n$stackTrace'),
      );
    }
  }

  @override
  Future<Result<bool, Exception>> requestPermission() async {
    // Desktop and web builds have no notification permission model to ask for.
    if (!isSupported) return const Result.success(false);

    try {
      final android = _android;
      // The platform channel is absent in headless runs (widget tests, unit
      // tests without the Android host), which is not an error: there is
      // simply nobody to ask.
      if (android == null) return const Result.success(false);
      final granted = await android.requestNotificationsPermission();
      return Result.success(granted ?? true);
    } on Object catch (error, stackTrace) {
      // A missing or broken channel is indistinguishable from a denial here;
      // callers treat both as "cannot notify right now".
      debugPrint('Notification permission unavailable: $error');
      debugPrintStack(stackTrace: stackTrace);
      return const Result.success(false);
    }
  }

  @override
  Future<Result<int, Exception>> notifyIfThresholdReached({
    required int currentCount,
    required int threshold,
    required int lastNotifiedCount,
  }) async {
    // A threshold of 0 (or less) means the user turned the feature off.
    if (!isSupported || threshold <= 0) {
      return Result.success(lastNotifiedCount);
    }

    final newItems = currentCount - lastNotifiedCount;
    // The count can go backwards when the feed shrinks (unsubscribing, a
    // filtered source). Treat that as "nothing new" instead of notifying.
    if (newItems < threshold) {
      return Result.success(lastNotifiedCount);
    }

    final initResult = await initialize();
    if (initResult case Error()) {
      return Result.success(lastNotifiedCount);
    }

    try {
      await _plugin.show(
        id: 0,
        title: 'New feed items',
        body: '$newItems new items in your feed',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'Feed updates',
            channelDescription: 'Notifies about new items in your feed',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
      await _preferences.set(
        PreferencesKey.feedUpdateNotificationLastCount,
        currentCount,
      );
      return Result.success(currentCount);
    } on Object catch (error, stackTrace) {
      return Result.error(
        Exception('Failed to show notification: $error\n$stackTrace'),
      );
    }
  }

  @override
  Future<void> dispose() async {
    _initialized = false;
  }
}
