import 'package:app/feature/video/player/playback_error.dart';
import 'package:test/test.dart';

void main() {
  group('MediaPlaybackException classification', () {
    test('classifies connection failures as network errors', () {
      final error = MediaPlaybackException.fromMessage(
        'connection timed out while opening media',
      );

      expect(error.category, PlaybackErrorCategory.network);
    });

    test('classifies codec failures as decoder errors', () {
      final error = MediaPlaybackException.fromMessage(
        'decoder rejected the unsupported codec',
      );

      expect(error.category, PlaybackErrorCategory.decoder);
    });

    test('classifies a stream that never opened as an open failure', () {
      final error = MediaPlaybackException.fromMessage(
        'Failed to open https://example.com/live.m3u8?expires=1&sign=abc',
      );

      expect(error.category, PlaybackErrorCategory.open);
    });

    test('classifies DRM license failures as DRM errors', () {
      final error = MediaPlaybackException.fromMessage(
        'Widevine license request failed',
      );

      expect(error.category, PlaybackErrorCategory.drm);
    });

    test('classifies rejected credentials as authorization errors', () {
      final error = MediaPlaybackException.fromMessage('HTTP 403 Forbidden');

      expect(error.category, PlaybackErrorCategory.authorization);
    });

    test('gives network indicators precedence over the open phrase', () {
      // media-kit prefixes connection failures with "Failed to open".
      final error = MediaPlaybackException.fromMessage(
        'Failed to open <url>: Connection timed out',
      );

      expect(error.category, PlaybackErrorCategory.network);
      expect(PlaybackRetryPolicy().shouldAutomaticallyRetry(error), isTrue);
    });

    test('does not read a signed URL as an authorization failure', () {
      // The live HLS URL carries expires= and an "401" path segment.
      final error = MediaPlaybackException.fromMessage(
        'Failed to open '
        'https://cdn.example.com/401/live.m3u8?expires=1700000000&sign=abc',
      );

      expect(error.category, PlaybackErrorCategory.open);
    });

    test('redacts media URLs before the message reaches the UI or the log', () {
      final error = MediaPlaybackException.fromMessage(
        'Failed to open '
        'https://cdn.example.com/live.m3u8?expires=1700000000&sign=abc&trid=x',
      );

      expect(error.message, 'Failed to open <url>');
      expect(error.message, isNot(contains('sign=')));
    });

    test('keeps unmatched failures in the unknown category', () {
      final error = MediaPlaybackException.fromMessage(
        'unexpected player stop',
      );

      expect(error.category, PlaybackErrorCategory.unknown);
    });
  });

  group('PlaybackRetryPolicy', () {
    const policy = PlaybackRetryPolicy(
      maxRetries: 3,
      initialDelay: Duration(milliseconds: 100),
      maxDelay: Duration(milliseconds: 250),
    );

    test('uses exponential backoff and caps the delay', () {
      expect(policy.delayForRetry(1), const Duration(milliseconds: 100));
      expect(policy.delayForRetry(2), const Duration(milliseconds: 200));
      expect(policy.delayForRetry(3), const Duration(milliseconds: 250));
    });

    test('only allows automatic retries for network failures', () {
      expect(
        policy.shouldAutomaticallyRetry(
          MediaPlaybackException.fromMessage('network timeout'),
        ),
        isTrue,
      );
      expect(
        policy.shouldAutomaticallyRetry(
          MediaPlaybackException.fromMessage('decoder failed'),
        ),
        isFalse,
      );
    });

    test('rejects invalid retry delays before scheduling a retry', () {
      const negativeInitialDelay = PlaybackRetryPolicy(
        initialDelay: Duration(seconds: -1),
      );
      const negativeMaxDelay = PlaybackRetryPolicy(
        maxDelay: Duration(seconds: -1),
      );
      const shorterMaxDelay = PlaybackRetryPolicy(
        initialDelay: Duration(seconds: 2),
        maxDelay: Duration(seconds: 1),
      );

      expect(() => negativeInitialDelay.delayForRetry(1), throwsArgumentError);
      expect(() => negativeMaxDelay.delayForRetry(1), throwsArgumentError);
      expect(() => shorterMaxDelay.delayForRetry(1), throwsArgumentError);
    });
  });
}
