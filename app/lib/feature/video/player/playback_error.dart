import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// The user-facing class of a failure reported by the media player.
enum PlaybackErrorCategory() {
  /// The stream could not be reached or the connection was interrupted.
  network,

  /// The media container or codec could not be decoded.
  decoder,

  /// A DRM-protected stream could not be unlocked.
  drm,

  /// The stream was rejected because credentials or authorization were invalid.
  authorization,

  /// The player reported an error that does not match a known category.
  unknown,
}

/// A normalized playback failure that does not expose media-kit types to UI.
@immutable
class const MediaPlaybackException({
  required final PlaybackErrorCategory category,
  required final String message,
}) extends Equatable implements Exception {
  /// Converts a media-kit error string into a stable application category.
  factory fromMessage(String message) {
    final normalized = message.toLowerCase();

    if (_containsAny(normalized, <String>[
      'drm',
      'widevine',
      'fairplay',
      'playready',
      'license',
      'decrypt',
      'encrypted',
      'key system',
    ])) {
      return MediaPlaybackException(
        category: PlaybackErrorCategory.drm,
        message: message,
      );
    }

    if (_containsAny(normalized, <String>[
      '401',
      '403',
      'unauthorized',
      'forbidden',
      'access denied',
      'permission denied',
      'authentication',
      'authorization',
      'invalid token',
      'token expired',
      'expired',
      'signature expired',
    ])) {
      return MediaPlaybackException(
        category: PlaybackErrorCategory.authorization,
        message: message,
      );
    }

    if (_containsAny(normalized, <String>[
      'network',
      'connection',
      'connect',
      'timeout',
      'timed out',
      'socket',
      'dns',
      'host',
      'unreachable',
      'refused',
      'reset by peer',
      'http 5',
      'server error',
    ])) {
      return MediaPlaybackException(
        category: PlaybackErrorCategory.network,
        message: message,
      );
    }

    if (_containsAny(normalized, <String>[
      'decode',
      'decoder',
      'codec',
      'demux',
      'unsupported format',
      'invalid data',
      'avcodec',
      'ffmpeg',
    ])) {
      return MediaPlaybackException(
        category: PlaybackErrorCategory.decoder,
        message: message,
      );
    }

    return MediaPlaybackException(
      category: PlaybackErrorCategory.unknown,
      message: message,
    );
  }

  @override
  List<Object?> get props => [category, message];

  @override
  String toString() => message;
}

bool _containsAny(String value, List<String> candidates) =>
    candidates.any(value.contains);

/// Controls automatic retries for transient playback failures.
@immutable
class const PlaybackRetryPolicy({
  final int maxRetries = 3,
  final Duration initialDelay = const Duration(seconds: 1),
  final int backoffMultiplier = 2,
  final Duration maxDelay = const Duration(seconds: 8),
}) extends Equatable {
  this : assert(maxRetries >= 0), assert(backoffMultiplier >= 1);

  /// Returns the delay before the one-based [retryNumber].
  Duration delayForRetry(int retryNumber) {
    if (retryNumber < 1) {
      throw ArgumentError.value(retryNumber, 'retryNumber');
    }
    _validateDelays();

    var delay = initialDelay;
    for (var attempt = 1; attempt < retryNumber; attempt++) {
      final nextDelay = delay * backoffMultiplier;
      delay = nextDelay > maxDelay ? maxDelay : nextDelay;
    }
    return delay;
  }

  void _validateDelays() {
    if (initialDelay.isNegative) {
      throw ArgumentError.value(
        initialDelay,
        'initialDelay',
        'must not be negative',
      );
    }
    if (maxDelay.isNegative) {
      throw ArgumentError.value(maxDelay, 'maxDelay', 'must not be negative');
    }
    if (maxDelay < initialDelay) {
      throw ArgumentError.value(
        maxDelay,
        'maxDelay',
        'must not be shorter than initialDelay',
      );
    }
  }

  /// Only network failures are retried automatically.
  bool shouldAutomaticallyRetry(MediaPlaybackException error) =>
      error.category == PlaybackErrorCategory.network;

  @override
  List<Object?> get props => [
    maxRetries,
    initialDelay,
    backoffMultiplier,
    maxDelay,
  ];
}
