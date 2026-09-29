import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'golden_font.dart';

/// 把「golden 里的文字是真字形」从偶然变成契约。
///
/// 链条有四环，每一环都可能被未来的改动悄悄打断：
///
///  1. 生产 app 不 bundle 字体：`pubspec.yaml` 没有 `fonts:` 声明，资源目录
///     里也没有字体资产。所以 `material_ui` 的 `ThemeData` 声明
///     `fontFamily: 'Roboto'` 时它解析不到，引擎回落到 `flutter test` 自带
///     的 Ahem。
///  2. Ahem 把每个字形画成 1em 宽的实心方块。于是「两字标题」和「四十字
///     标题」在基线里一样宽 —— 文字溢出、错误换行这类 bug 对 golden 完全
///     不可见。
///  3. `test/fonts/` 下的子集把这条回落替换掉，代价是它必须**只**在测试里
///     生效：一旦被 `pubspec.yaml` 的 `fonts:` 或 `assets:` 捡走，生产像素和
///     APK 体积就跟着变。
///  4. 加载方式是 [FontLoader] 而非 `fonts:` 声明，因此字体只活在测试进程
///     里；`rootBundle` 读不到它，`flutter build` 也不会打包它。
///
/// 判断「真字形」不能量宽度：CJK 字形本来就是 1em 全角，豆腐块（notdef）也
/// 是 1em，两者宽度完全相同 —— 宽度探针在这里恒等无效。唯一可靠的判别法是
/// 像素：豆腐块对任何字符渲染出同一张图，真字体则不然。
Future<List<int>> _renderPixels(
  String text, {
  String? family,
  double fontSize = 40,
}) async {
  final recorder = ui.PictureRecorder();
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: family,
        fontSize: fontSize,
        color: const Color(0xFF000000),
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(Canvas(recorder), Offset.zero);
  final image = await recorder.endRecording().toImage(64, 48);
  final data = await image.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  );
  final bytes = data!.buffer.asUint8List();
  image.dispose();
  return bytes.toList();
}

int _differingBytes(List<int> a, List<int> b) {
  var differing = 0;
  for (var i = 0; i < a.length && i < b.length; i++) {
    if (a[i] != b[i]) differing++;
  }
  return differing;
}

void main() {
  group('golden font contract', () {
    testWidgets('the subset renders distinct glyphs, not tofu boxes', (
      tester,
    ) async {
      await loadGoldenFont();
      await tester.runAsync(() async {
        final zhong = await _renderPixels('中', family: goldenFontFamily);
        final wen = await _renderPixels('文', family: goldenFontFamily);

        // 豆腐块（notdef）对任何字符渲染出同一张图，所以这两个字节序列必然
        // 相同。真字体下它们是「中」和「文」两套完全不同的笔画。
        expect(
          _differingBytes(zhong, wen),
          greaterThan(0),
          reason:
              'every CJK glyph rendered identically, so the subset is not '
              'actually being used and goldens are back to Ahem boxes',
        );
      });
    });

    testWidgets('the theme family reaches the text', (tester) async {
      // 探针（2026-09-29）实测：`Theme` 套在 `MaterialApp` 外面无效，
      // `Theme.of(context).textTheme.bodyMedium.fontFamily` 仍是 'Roboto'
      // —— `material_ui` 的 `MaterialApp` 自建 ThemeData，把外层 shadow
      // 掉了。必须交给那个 `MaterialApp` 的 `theme:`。
      await loadGoldenFont();
      await tester.pumpWidget(
        MaterialApp(
          theme: goldenTestTheme(),
          home: Scaffold(body: const Text('中文标题')),
        ),
      );
      final ctx = tester.element(find.byType(Text));
      expect(Theme.of(ctx).textTheme.bodyMedium?.fontFamily, goldenFontFamily);
      expect(DefaultTextStyle.of(ctx).style.fontFamily, goldenFontFamily);
    });

    testWidgets('the subset is proportional, unlike the Ahem fallback', (
      tester,
    ) async {
      await loadGoldenFont();
      double widthOf(String text, {String? family}) {
        final painter = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(fontFamily: family, fontSize: 20),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        return painter.width;
      }

      // Ahem 对 'i' 和 'W' 一视同仁（都是 1em）；真字体里 'i' 约 0.28em、
      // 'W' 约 0.88em。这一条断了就说明加载没生效。
      expect(widthOf('i', family: goldenFontFamily), lessThan(20.0));
      expect(
        widthOf('W', family: goldenFontFamily),
        greaterThan(widthOf('i', family: goldenFontFamily) * 2),
      );
    });

    testWidgets('rendering the same text twice is byte-identical', (
      tester,
    ) async {
      // 重录基线的前提：同一次运行里同一段文字必须渲染出同样的字节，否则
      // `--update-goldens` 产出的基线自身就不确定。
      await loadGoldenFont();
      await tester.runAsync(() async {
        final first = await _renderPixels('中文标题', family: goldenFontFamily);
        final second = await _renderPixels('中文标题', family: goldenFontFamily);
        expect(_differingBytes(first, second), 0);
      });
    });

    test('the subset covers every character the app can render', () {
      // 子集只收了 `lib/` 与 `test/` 字符串字面里出现过的字，外加 ASCII 与
      // 常用符号。将来新增文案时如果用到了子集外的字，那一个字会静默退回
      // 豆腐块 —— 基线看着正常，实际那个字没被验过。这一条把它变成红灯。
      final font = File('test/fonts/NotoSansSC-golden-subset.otf');
      expect(font.existsSync(), isTrue, reason: 'run from app/');

      final literals = <String>{};
      final pattern = RegExp(r''' '([^'\\\n]*)'|"([^"\\\n]*)" ''');
      for (final dir in ['lib', 'test']) {
        for (final entity in Directory(dir).listSync(recursive: true)) {
          if (entity is! File || !entity.path.endsWith('.dart')) continue;
          for (final line in entity.readAsLinesSync()) {
            // 去掉行注释，免得把注释里的中文算成待验字符。
            for (final match in pattern.allMatches(
              line.replaceAll(RegExp(r'//.*$'), ''),
            )) {
              literals.add(match.group(1) ?? match.group(2) ?? '');
            }
          }
        }
      }

      // 子集覆盖的字符集由子集化脚本决定，仓库里存一份快照供比对。
      final covered = File('test/fonts/subset-characters.txt');
      expect(
        covered.existsSync(),
        isTrue,
        reason: 'run from app/; the character list ships beside the font',
      );
      final subsetChars = covered.readAsLinesSync().join().split('');
      expect(subsetChars.toSet().length, greaterThan(400));

      final uncovered = <String>{};
      for (final literal in literals) {
        for (final ch in literal.split('')) {
          if (ch.codeUnitAt(0) <= 0x7f) continue;
          if (!subsetChars.contains(ch)) uncovered.add(ch);
        }
      }
      expect(
        uncovered,
        isEmpty,
        reason:
            'these characters appear in app strings but not in the golden '
            'font subset; they would render as tofu in every baseline. '
            'Re-subset with: $uncovered',
      );
    });

    test('the subset stays out of the production bundle', () {
      // 第 3 环：`fonts:` 或 `assets:` 声明任一都会把 207 KB 字体带进 APK，
      // 并让生产主题开始用这个字族 —— 那是一次没走设计系统的像素变更。
      final pubspec = File('pubspec.yaml');
      expect(pubspec.existsSync(), isTrue, reason: 'run from app/');
      final yaml = pubspec.readAsStringSync();
      expect(
        yaml,
        isNot(contains('fonts:')),
        reason: 'a `fonts:` block would ship the golden subset to production',
      );
      expect(
        yaml,
        isNot(contains('test/fonts/')),
        reason: 'an `assets:` entry would ship the golden subset to production',
      );
    });
  });
}
