import 'package:alchemist/alchemist.dart';
import 'package:app/feature/not_found/not_found_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'golden_font.dart';

void main() {
  group('NotFoundScreen golden', () {
    goldenTest(
      'renders sanitized variants',
      fileName: 'not_found_screen',
      // bili 用 material_ui 这个 fork，自带 MaterialApp/ThemeData；alchemist
      // 内置脚手架用的是 Flutter material，树必须用 fork 的 app 包，否则
      // MaterialLocalizations 找不到。
      pumpWidget: (tester, widget) async {
        await loadGoldenFont();
        await tester.pumpWidget(
          MaterialApp(
            theme: goldenTestTheme(),
            home: Scaffold(body: Center(child: widget)),
          ),
        );
        await tester.pumpAndSettle();
      },
      builder: () => GoldenTestGroup(
        columns: 1,
        // NotFoundScreen 自带 Scaffold+AppBar，需要宽度上界；竖排三个场景。
        scenarioConstraints: const BoxConstraints(
          maxWidth: 360,
          maxHeight: 600,
        ),
        children: [
          GoldenTestScenario(
            name: 'plain uri and path',
            child: const NotFoundScreen(
              uri: 'https://example.com/missing',
              path: '/missing',
            ),
          ),
          // query 参数值必须被遮蔽成 REDACTED：这是 404 页防凭据外泄的唯一
          // 手段，遮蔽失效会直接体现在像素上（token 明文出现）。
          GoldenTestScenario(
            name: 'query params redacted',
            child: const NotFoundScreen(
              uri: 'https://example.com/missing?token=[REDACTED]',
              path: '/missing',
            ),
          ),
          // 控制字符被 sanitize 剥掉后不应换行或留出空段。
          GoldenTestScenario(
            name: 'control characters stripped',
            child: const NotFoundScreen(
              uri: 'https://example.com/missing\n',
              path: '/missing\nnested',
            ),
          ),
        ],
      ),
    );
  });
}
