import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:cached_network_image_ce/cached_network_image.dart';
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
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // `flutter test` runs test files concurrently, so the image cache must not be
  // shared between them. With one fixed directory, whichever file fetches a
  // thumbnail first writes it, and every other file then gets a cache hit and
  // never issues the request `mockNetworkImagesFor` is there to intercept — the
  // rendered image would depend on which file happened to run first. A unique
  // root per test executable, removed on the way out, keeps each run hermetic
  // and leaves nothing behind in the system temp dir.
  final root = Directory.systemTemp.createTempSync('bili_test_');
  _sweepStaleRoots();
  PathProviderPlatform.instance = FakePathProviderPlatform(root.path);

  try {
    await AlchemistConfig.runWithConfig(
      config: AlchemistConfig(
        platformGoldensConfig: const PlatformGoldensConfig(enabled: false),
        ciGoldensConfig: const CiGoldensConfig(diffThreshold: 0.01),
      ),
      run: testMain,
    );
  } finally {
    // The cache manager is a lazily created singleton: reading it here forces
    // construction even if no test rendered a thumbnail. Cleanup must not turn
    // a green run red, so failures here are reported and swallowed.
    try {
      await CachedNetworkImageProvider.defaultCacheManager.emptyCache();
      await CachedNetworkImageProvider.defaultCacheManager.dispose();
    } on Object catch (error) {
      stderr.writeln('bili_test: image cache cleanup failed: $error');
    }
    if (root.existsSync()) root.deleteSync(recursive: true);
  }
}

/// Deletes cache roots left behind by earlier runs.
///
/// `flutter test` tears its isolates down as soon as the run reports, so the
/// `finally` cleanup does not always get to run and a few roots survive. A run
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
