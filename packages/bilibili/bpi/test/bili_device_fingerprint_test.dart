import 'dart:convert';
import 'dart:math';

import 'package:bpi/src/device/bili_device_fingerprint.dart';
import 'package:test/test.dart';

void main() {
  test('forges the four dm_img parameters the web player sends', () {
    final device = BiliDeviceFingerprint.forge(random: Random(7));

    expect(BiliDeviceFingerprint.dmImgList, equals('[]'));
    expect(device.dmImgStr, isNotEmpty);
    expect(device.dmCoverImgStr, isNotEmpty);

    final interaction = jsonDecode(device.dmImgInter) as Map<String, dynamic>;
    expect(interaction['ds'], isEmpty);
    expect(interaction['wh'], hasLength(3));
    expect(interaction['of'], hasLength(3));
  });
}
