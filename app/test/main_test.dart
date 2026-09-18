import 'package:app/main.dart';
import 'package:bilibili/bilibili.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_debug_overlay/flutter_debug_overlay.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'initDebugOverlayBridge configures debug overlay and http client correctly',
    () {
      initDebugOverlayBridge();

      if (kReleaseMode) {
        expect(DebugOverlay.enabled, isFalse);
        expect(Bili.client, isNot(isA<HttpLogClient>()));
      } else {
        expect(DebugOverlay.enabled, isTrue);
        expect(Bili.client, isA<HttpLogClient>());
      }
    },
  );
}
