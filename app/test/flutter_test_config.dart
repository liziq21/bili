import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Every path_provider lookup in a widget test resolves to a real temp dir.
///
/// `cached_network_image_ce`'s `DefaultCacheManager` calls
/// `getTemporaryDirectory()` while initialising, and VideoCard builds a
/// `CachedNetworkImage` directly with no way to inject a cache manager. Without
/// this fake, every golden test that renders a thumbnail dies on
/// `MissingPluginException` for `plugins.flutter.io/path_provider`.
class FakePathProviderPlatform() extends PathProviderPlatform {
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

  static String _dir(String name) {
    final dir = Directory('${Directory.systemTemp.path}/bili_test/$name');
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
  PathProviderPlatform.instance = FakePathProviderPlatform();

  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      platformGoldensConfig: const PlatformGoldensConfig(enabled: false),
      ciGoldensConfig: const CiGoldensConfig(diffThreshold: 0.01),
    ),
    run: testMain,
  );
}
