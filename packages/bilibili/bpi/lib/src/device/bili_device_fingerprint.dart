import 'dart:convert';
import 'dart:math';

/// Browser-side fingerprint parameters Bilibili's web player sends with
/// `x/player/wbi/playurl`.
///
/// Without all four `dm_img_*` parameters the endpoint caps anonymous
/// requests at 480P even when `try_look=1` is present. Sending them together
/// with `try_look=1` lets a logged-out client receive the 1080P DASH ladder.
/// The values are derived from a forged desktop browser, mirroring the web
/// player; they carry no account identity.
final class BiliDeviceFingerprint {
  BiliDeviceFingerprint._({
    required this.dmImgStr,
    required this.dmCoverImgStr,
    required this.dmImgInter,
  });

  factory BiliDeviceFingerprint.forge({Random? random}) {
    final rng = random ?? Random();
    final innerWidth = 1920 - 60 - rng.nextInt(60);
    final innerHeight = 1080 - 90 - rng.nextInt(60);
    final whRandom = rng.nextInt(114);
    final wh = <int>[
      2 * innerWidth + 2 * innerHeight + 3 * whRandom,
      4 * innerWidth - innerHeight + whRandom,
      whRandom,
    ];
    final ofRandom = rng.nextInt(514);
    final of = <int>[ofRandom, 2 * ofRandom, ofRandom];

    return BiliDeviceFingerprint._(
      dmImgStr: _base64Prefix('WebGL 1.0 (OpenGL ES 2.0 Chromium)'),
      dmCoverImgStr: _base64Prefix(
        'ANGLE (Intel, Intel(R) UHD Graphics 630 Direct3D11 vs_5_0 ps_5_0, '
        'D3D11)Google Inc. (Intel)',
      ),
      dmImgInter:
          '{"ds":[],"wh":[${wh.join(',')}],'
          '"of":[${of.join(',')}]}',
    );
  }

  /// The web player always sends an empty drag-list.
  static const dmImgList = '[]';

  final String dmImgStr;
  final String dmCoverImgStr;
  final String dmImgInter;

  /// The web player strips the last two base64 characters before sending.
  static String _base64Prefix(String raw) {
    final encoded = base64.encode(utf8.encode(raw));
    return encoded.substring(0, encoded.length - 2);
  }
}
