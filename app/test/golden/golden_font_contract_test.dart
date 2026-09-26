import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// 把「golden 里的文字为什么是实心方块」从偶然变成契约。
///
/// 链条有四环，每一环都可能被未来的改动悄悄打断：
///
///  1. `material_ui` 的 `ThemeData` 默认把 `textTheme` 的 `fontFamily` 设成
///     `'Roboto'`——注意是**有值的**，不是 null。
///  2. 仓库不 bundle 任何字体：`pubspec.yaml` 没有 `fonts:` 声明，资源目录
///     里也没有 `.ttf`/`.otf`。所以 `'Roboto'` 永远解析不到。
///  3. 引擎回退到 `flutter test` 自带的字体。实测度量：每个字形恰好 1em 宽
///     （`'i'`、`'W'`、`'M'`、`'-'`、数字全是一样宽），也就是渲染成实心方块。
///  4. 录制好的基线正是这个形态——打开 `goldens/ci/video_card.png` 能看到
///     文字全是黑块。
///
/// 第 2 环最脆：哪天有人 bundle 了 Roboto 或任何字体，第 3 环的等宽方块假设
/// 立刻失效，所有基线在别的平台上对不上，而 CI 只在 `ubuntu-latest` 比对，
/// 本地看不一定发现得了。下面的测试就是为了让这种改动当场变红，而不是等到
/// 某天基线对不上才去查。
///
/// 另一半真相：Alchemist 的 `FlutterGoldenTestWrapper` 会把 Ahem 施加到
/// **它自己**那层 `MaterialApp` 的 theme 上，而我们在它内部又套了一层
/// `material_ui.MaterialApp`（bili 用的是 fork，见 #96），内层自建 ThemeData，
/// 外层那个字体设置被丢掉。换言之当前生效的字体是「回落」来的，不是
/// 「配置」来的——这正是本文件要钉住的那条隐式路径。
double _textWidth(String text, {String? family, double fontSize = 20}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontFamily: family, fontSize: fontSize),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  return painter.width;
}

void main() {
  group('golden font contract', () {
    testWidgets('the theme declares Roboto, not a resolved family', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: const Text('x'))),
      );
      final ctx = tester.element(find.byType(Text));
      expect(Theme.of(ctx).textTheme.bodyMedium?.fontFamily, 'Roboto');
      expect(DefaultTextStyle.of(ctx).style.fontFamily, 'Roboto');
    });

    testWidgets('Roboto is unresolvable, so it lands on the same font', (
      tester,
    ) async {
      // 第 2 + 3 环：声明了 'Roboto'，但它解析不到，于是与不声明族走同一个
      // 回退字体。真字体的 'i' 只有 0.2em 上下，两者宽度一旦不同，就说明有
      // 字体被 bundle 了。
      expect(
        _textWidth('iiiiiiii', family: 'Roboto'),
        closeTo(_textWidth('iiiiiiii'), 0.01),
      );
    });

    testWidgets('the effective font draws every glyph 1em wide', (tester) async {
      // 第 3 环的签名，也是基线里文字长成这样的原因。等宽方块字体对 'i' 和
      // 'W' 一视同仁；任何真字体的这两个宽度都差好几倍。
      for (final glyph in ['i', 'W', 'M', '-', '1', '8']) {
        expect(
          _textWidth(glyph, fontSize: 20),
          closeTo(20.0, 0.01),
          reason: 'glyph "$glyph" should be one em wide',
        );
      }
      expect(_textWidth('iiiiiiii', fontSize: 20), closeTo(160.0, 0.05));
    });

    test('the repo bundles no font that could shadow the fallback', () {
      // 第 2 环，根因。Flutter 只会加载 pubspec 里 `fonts:` 声明的字体，所以
      // 这一条断了，第 2 环就断了。baseline 是按实心方块录的，有人 bundle
      // 字体等于一次性改掉所有 golden。
      final pubspec = File('pubspec.yaml');
      expect(pubspec.existsSync(), isTrue, reason: 'run from app/');
      expect(
        pubspec.readAsStringSync(),
        isNot(contains('fonts:')),
        reason: 'bundling a font invalidates every recorded golden baseline',
      );
    });
  });
}
