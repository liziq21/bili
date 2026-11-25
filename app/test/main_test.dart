import 'package:app/main.dart';
import 'package:bilibili/bilibili.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
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

  test('live stream probing never reuses the buffering logging client', () {
    initDebugOverlayBridge();

    // #664：debug 构建的 Bili.client 是 HttpLogClient，它在 send() 里把整个
    // 响应 body 缓冲完才返回。直播流是无限响应，探测必然超时，直播间在
    // debug 下 100% 加载失败。探测必须走独立的、不带缓冲的客户端。
    final probeClient = Bili.probeClientFactory();
    addTearDown(probeClient.close);

    expect(probeClient, isNot(isA<HttpLogClient>()));
    expect(identical(probeClient, Bili.client), isFalse);
  });

  test('live room data source probes through Bili.probeClientFactory', () {
    // 上面的断言只证明工厂产出的客户端不带缓冲，证明不了直播数据源真的用它：
    // 数据源若退回共享客户端，debug 下的超时同样会回来。
    MockClient createProbeClient() =>
        MockClient((_) async => http.Response('', 200));
    final original = Bili.probeClientFactory;
    Bili.probeClientFactory = createProbeClient;
    final bili = Bili();
    addTearDown(() {
      Bili.probeClientFactory = original;
      bili.close();
    });

    final source = bili.liveRoomDetailDataSource;

    expect(source, isA<BiliLiveRoomDetailRemoteDataSource>());
    expect(identical(source.clientFactory, createProbeClient), isTrue);
  });

  testWidgets(
    'ErrorWidget.builder handles build errors securely based on build mode',
    (tester) async {
      final originalBuilder = ErrorWidget.builder;

      // Set up ErrorWidget.builder exactly as main() does
      ErrorWidget.builder = (details) => SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Text(
          kReleaseMode
              ? 'A rendering error occurred.'
              : 'Build error: ${details.exception}\n\n${details.stack}',
          textDirection: TextDirection.ltr,
        ),
      );

      final details = FlutterErrorDetails(
        exception: Exception('sensitive_secret_data'),
        stack: StackTrace.current,
      );

      final widget = ErrorWidget.builder(details);

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      if (kReleaseMode) {
        expect(find.text('A rendering error occurred.'), findsOneWidget);
        expect(find.textContaining('sensitive_secret_data'), findsNothing);
      } else {
        expect(find.textContaining('sensitive_secret_data'), findsOneWidget);
      }

      // Restore before test ends to satisfy test framework
      ErrorWidget.builder = originalBuilder;
    },
  );
}
