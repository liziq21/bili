import 'package:model/model.dart';

/// Sends a local notification when the feed gained enough new items.
///
/// The contract is deliberately narrow: callers poll their feed, then hand the
/// current item count to [notifyIfThresholdReached] together with the last
/// count they were acknowledged for. The implementation decides whether a
/// notification is due, so feed loaders do not need to know about channels,
/// permissions or platform differences.
///
/// Implementations must never throw: failures come back as [Error] results and
/// the caller keeps working with its previous count.
abstract interface class FeedUpdateNotifier() {
  /// Whether this platform can deliver feed update notifications at all.
  bool get isSupported;

  /// Fires when the user taps a feed update notification.
  ///
  /// Also fires for a cold start where the notification launched the app, so
  /// subscribers do not need to distinguish "app was already running" from
  /// "app was just started by the tap". A cold-start signal is buffered until
  /// the first listener arrives.
  Stream<void> get feedOpened;

  /// Prepares the platform notification system (channel and plugin).
  ///
  /// Registers the tap handler and drains a pending cold-start tap, so call it
  /// once at startup. Does not prompt for permission; use
  /// [requestPermission] for that, from a place where a system dialog is
  /// expected. Safe to call repeatedly.
  Future<Result<void, Exception>> initialize();

  /// Asks the user for notification permission.
  ///
  /// Returns `true` when notifications may be shown. On platforms without a
  /// permission model (or unsupported platforms) this reports the platform's
  /// capability without showing any dialog.
  Future<Result<bool, Exception>> requestPermission();

  /// Notifies the user when `currentCount - lastNotifiedCount >= threshold`.
  ///
  /// A [threshold] of 0 disables notifications. Returns the count the caller
  /// should remember for the next call: the new [currentCount] when a
  /// notification was shown, otherwise the unchanged [lastNotifiedCount].
  Future<Result<int, Exception>> notifyIfThresholdReached({
    required int currentCount,
    required int threshold,
    required int lastNotifiedCount,
  });

  /// Releases plugin resources.
  Future<void> dispose();
}
