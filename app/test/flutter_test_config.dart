import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/foundation.dart' show BindingBase, kIsWeb;
import 'package:flutter/painting.dart' show PaintingBinding;
import 'package:flutter_test/flutter_test.dart' show tearDown, tearDownAll;
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Every path_provider lookup in a widget test resolves under [root].
///
/// `cached_network_image_ce`'s `DefaultCacheManager` calls
/// `getTemporaryDirectory()` while initialising, and VideoCard builds a
/// `CachedNetworkImage` directly with no way to inject a cache manager. Without
/// this fake, every golden test that renders a thumbnail dies on
/// `MissingPluginException` for `plugins.flutter.io/path_provider`.
class FakePathProviderPlatform(final String _root)
    extends PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async => _dir('tmp');

  @override
  Future<String?> getApplicationSupportPath() async => _dir('support');

  @override
  Future<String?> getApplicationDocumentsPath() async => _dir('documents');

  @override
  Future<String?> getApplicationCachePath() async => _dir('cache');

  @override
  Future<String?> getLibraryPath() async => _dir('library');

  @override
  Future<String?> getDownloadsPath() async => _dir('downloads');

  String _dir(String name) {
    final dir = Directory('$_root/$name');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir.path;
  }
}

/// Global Alchemist configuration for every test in this package.
///
/// Only CI goldens are enabled. CI goldens render through the Ahem font with
/// all text obscured into solid blocks, which makes the output byte-identical
/// across macOS, Linux and Windows. That is what lets a baseline committed
/// from a dev machine match `ubuntu-latest` in CI. Platform goldens stay off
/// so nobody records a readable baseline that can never pass on CI.
/// Whether leak tracking is enabled for every `testWidgets` in this package.
///
/// Off unless the run opts in, through either `--dart-define LEAK_TRACKING=true`
/// at compile time or `LEAK_TRACKING=true` in the environment, matching how the
/// Flutter framework gates the same facility
/// (`packages/flutter/test/flutter_test_config.dart`).
///
/// Leak tracking reports every disposable object that survived the test that
/// created it — an undisposed `StreamController`, `FocusNode`, `Timer`, or
/// Bloc. Measured on `main` at 662a7e9 with this switch on: the widget and bloc
/// test files report no leaks, while `test/golden/video_card_golden_test.dart`
/// reports two undisposed `ImageStreamCompleterHandle` objects per run before
/// the image cache teardown below was added.
bool _isLeakTrackingEnabled() {
  if (kIsWeb) {
    return false;
  }
  // The two forms are not interchangeable: the first is a compile-time
  // constant, the second is read from the environment of the test process.
  return const bool.fromEnvironment('LEAK_TRACKING') ||
      (bool.tryParse(Platform.environment['LEAK_TRACKING'] ?? '') ?? false);
}

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  if (_isLeakTrackingEnabled()) {
    LeakTesting.enable();
    // The tracking implementations are only wired up on the platforms the
    // widget tester runs on here (Linux and macOS CI, Linux locally); leaving
    // the warning on makes every widget test report an unsupported platform.
    LeakTracking.warnForUnsupportedPlatforms = false;
    // Objects a test itself creates are not the code under test, so they are
    // excluded from the report. This is the Flutter framework's own setting.
    LeakTesting.settings = LeakTesting.settings.withIgnored(
      createdByTestHelpers: true,
    );
  }

  // Every thumbnail in this app is loaded through a network image, and both
  // the mocked HttpClient in tests and `CachedNetworkImage` at runtime register
  // a completer with the binding-wide `PaintingBinding.instance.imageCache`.
  // Disposing the widget tree does not dispose those completers or the live
  // image tracking objects, and the cache is shared by the whole test
  // executable, so a thumbnail loaded in one test is still held when a later
  // test in the same file runs its leak check. Measured with leak tracking on
  // `main` at 662a7e9: this teardown takes
  // `test/golden/video_card_golden_test.dart` from two undisposed
  // `ImageStreamCompleterHandle` objects plus one `_LiveImage` down to one
  // handle. The remaining handle comes from the `cached_network_image_ce`
  // decode path rather than from this cache; its owner is not established.
  tearDown(() {
    // The Drift database suite and the pure Dart package tests never
    // initialize the Flutter binding, so there is no image cache to reach.
    if (BindingBase.debugBindingType() == null) {
      return;
    }
    final imageCache = PaintingBinding.instance.imageCache;
    imageCache.clear();
    imageCache.clearLiveImages();
  });

  // `flutter test` runs test files concurrently, so the image cache must not be
  // shared between them. With one fixed directory, whichever file fetches a
  // thumbnail first writes it, and every other file then gets a cache hit and
  // never issues the request `mockNetworkImagesFor` is there to intercept — the
  // rendered image would depend on which file happened to run first. A unique
  // root per test executable, removed when the executable finishes, keeps each
  // run hermetic and leaves nothing behind in the system temp dir.
  final root = Directory.systemTemp.createTempSync('bili_test_');
  _sweepStaleRoots();
  PathProviderPlatform.instance = FakePathProviderPlatform(root.path);

  // testMain only declares the tests; the framework runs their bodies after it
  // returns. A `finally` around it therefore deletes the root before any
  // thumbnail is loaded, and the bodies recreate it through
  // [FakePathProviderPlatform._dir], so the cache written by the run survived:
  // one `flutter test test/golden/video_card_golden_test.dart` left one fresh
  // root behind. tearDownAll is the first hook that runs after the last test
  // body of this executable.
  //
  // The root is removed synchronously and the cache manager is left alone:
  // deleting the root already removes everything the manager wrote, because
  // both its cache directory and its Hive box live under the path_provider
  // root (cached_network_image_ce default_cache_manager.dart, `_doInit`).
  // Its two async teardown calls cannot be awaited here — measured, each one
  // hangs the run past the 300s test timeout after the bodies have executed,
  // while the same calls complete before them. `dispose()` blocks on the
  // cleanup sweep `_doInit` launched from inside a test body (lines 220 and
  // 766); the reason `emptyCache()` blocks is not established.
  tearDownAll(() {
    try {
      if (root.existsSync()) root.deleteSync(recursive: true);
    } on FileSystemException catch (error) {
      // A root that cannot be removed is reclaimed by [_sweepStaleRoots] on a
      // later run. Cleanup must not turn a green run red.
      stderr.writeln('bili_test: temp root cleanup failed: $error');
    }
  });

  await AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      platformGoldensConfig: const PlatformGoldensConfig(enabled: false),
      ciGoldensConfig: const CiGoldensConfig(diffThreshold: 0.01),
    ),
    run: testMain,
  );
}

/// Deletes cache roots left behind by earlier runs.
///
/// `flutter test` tears its isolates down as soon as the run reports, so the
/// teardown hook does not always get to run and a few roots survive. A run
/// cannot blanket-delete them: test files in the same run execute concurrently
/// and each one owns a live root, so only roots older than [_staleAfter] are
/// removed. That is old enough to spare any sibling of the current run and new
/// enough to reclaim a crashed run on the next invocation.
const Duration _staleAfter = Duration(hours: 1);

void _sweepStaleRoots() {
  final cutoff = DateTime.now().subtract(_staleAfter);
  for (final entity in Directory.systemTemp.listSync(followLinks: false)) {
    if (!entity.path
        .split(Platform.pathSeparator)
        .last
        .startsWith('bili_test_')) {
      continue;
    }
    try {
      if (entity.statSync().modified.isBefore(cutoff)) {
        entity.deleteSync(recursive: true);
      }
    } on FileSystemException {
      // A sibling is still using it, or the OS already reclaimed it.
    }
  }
}
