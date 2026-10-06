import 'package:app/utils/platfrom_info.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for the platform predicates.
///
/// Every one of these reads `defaultTargetPlatform`, which the test runner
/// reports as the host platform (Linux). A predicate that forgets to check the
/// platform it belongs to therefore still returns `true` here, which is why
/// each case drives `debugDefaultTargetPlatformOverride` explicitly instead of
/// asserting against the host.
///
/// `kIsWeb` is `false` in the VM, so the `!kIsWeb` conjuncts are exercised but
/// the web branch of `isDesktopOrWeb` cannot be reached from here.
void main() {
  group('PlatformInfo desktop and mobile classification', () {
    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    void runAs(TargetPlatform platform, void Function() body) {
      debugDefaultTargetPlatformOverride = platform;
      body();
    }

    test('macOS counts as desktop and not mobile', () {
      runAs(TargetPlatform.macOS, () {
        expect(PlatformInfo.isDesktop, isTrue);
        expect(PlatformInfo.isMobile, isFalse);
        expect(PlatformInfo.isMacOS, isTrue);
        expect(PlatformInfo.isWindows, isFalse);
        expect(PlatformInfo.isLinux, isFalse);
        expect(PlatformInfo.isAndroid, isFalse);
        expect(PlatformInfo.isIOS, isFalse);
      });
    });

    test('Windows counts as desktop and not mobile', () {
      runAs(TargetPlatform.windows, () {
        expect(PlatformInfo.isDesktop, isTrue);
        expect(PlatformInfo.isMobile, isFalse);
        expect(PlatformInfo.isWindows, isTrue);
        expect(PlatformInfo.isMacOS, isFalse);
      });
    });

    test('Linux counts as desktop and not mobile', () {
      runAs(TargetPlatform.linux, () {
        expect(PlatformInfo.isDesktop, isTrue);
        expect(PlatformInfo.isMobile, isFalse);
        expect(PlatformInfo.isLinux, isTrue);
        expect(PlatformInfo.isWindows, isFalse);
      });
    });

    test('Android counts as mobile and not desktop', () {
      runAs(TargetPlatform.android, () {
        expect(PlatformInfo.isMobile, isTrue);
        expect(PlatformInfo.isDesktop, isFalse);
        expect(PlatformInfo.isAndroid, isTrue);
        expect(PlatformInfo.isIOS, isFalse);
      });
    });

    test('iOS counts as mobile and not desktop', () {
      runAs(TargetPlatform.iOS, () {
        expect(PlatformInfo.isMobile, isTrue);
        expect(PlatformInfo.isDesktop, isFalse);
        expect(PlatformInfo.isIOS, isTrue);
        expect(PlatformInfo.isAndroid, isFalse);
      });
    });

    test('a desktop platform is also desktop-or-web', () {
      runAs(TargetPlatform.macOS, () {
        expect(PlatformInfo.isDesktopOrWeb, isTrue);
      });
    });

    test('a mobile platform is neither desktop nor desktop-or-web', () {
      runAs(TargetPlatform.android, () {
        expect(PlatformInfo.isDesktopOrWeb, isFalse);
      });
    });

    test('exactly one of isDesktop and isMobile holds per classified '
        'platform', () {
      // Fuchsia is deliberately absent: it is in neither list, so it is
      // asserted separately rather than folded into this loop.
      const classified = [
        TargetPlatform.macOS,
        TargetPlatform.windows,
        TargetPlatform.linux,
        TargetPlatform.android,
        TargetPlatform.iOS,
      ];

      for (final platform in classified) {
        runAs(platform, () {
          expect(
            PlatformInfo.isDesktop ^ PlatformInfo.isMobile,
            isTrue,
            reason: 'platform $platform matched neither or both categories',
          );
        });
      }
    });

    test('Fuchsia belongs to neither category', () {
      runAs(TargetPlatform.fuchsia, () {
        expect(PlatformInfo.isDesktop, isFalse);
        expect(PlatformInfo.isMobile, isFalse);
        expect(PlatformInfo.isDesktopOrWeb, isFalse);
      });
    });

    test('at most one OS predicate holds per platform', () {
      for (final platform in TargetPlatform.values) {
        runAs(platform, () {
          final matched = [
            PlatformInfo.isWindows,
            PlatformInfo.isLinux,
            PlatformInfo.isMacOS,
            PlatformInfo.isAndroid,
            PlatformInfo.isIOS,
          ].where((flag) => flag).length;
          expect(
            matched,
            lessThanOrEqualTo(1),
            reason: 'platform $platform matched more than one OS predicate',
          );
        });
      }
    });
  });
}
