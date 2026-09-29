import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
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

/// Collects every non-ASCII character that appears in a Dart string literal
/// under [dirs].
///
/// Uses `package:analyzer`'s scanner rather than a regular expression. A
/// regex over raw source text gets string quoting wrong in ways that are
/// silent rather than loud: a literal bounded by a space on the wrong side
/// misses `('热门')` and `['热门']`, and stripping `//.*$` before matching
/// truncates any literal that contains a URL, so `https://example.com/路径`
/// is cut down to `https:` and the characters after the slash are never seen.
/// Both failures make this test pass while missing characters.
Set<int> _stringLiteralRunes(List<String> dirs) {
  final codePoints = <int>{};
  for (final dir in dirs) {
    for (final entity in Directory(dir).listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final result = parseString(
        content: entity.readAsStringSync(),
        path: entity.path,
        throwIfDiagnostics: false,
      );
      result.unit.accept(_CodePointCollector(codePoints));
    }
  }
  return codePoints.where((rune) => rune > 0x7f).toSet();
}

/// Adds the code points of every string literal it visits to [sink].
// ignore: use_declaring_parameters
class _CodePointCollector(this._sink) extends RecursiveAstVisitor<dynamic> {
  final Set<int> _sink;

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    // Iterate runes, not `split('')`. Splitting by UTF-16 code unit tears an
    // astral character such as U+1F44D into two lone surrogates, and each half
    // then looks like an ordinary BMP character: the astral-range check stops
    // skipping it, and it gets reported as a missing glyph under a name that
    // only renders as U+FFFD.
    _sink.addAll(node.value.runes);
  }
}

/// Reads the character map out of the font file itself.
///
/// The subset's coverage is a property of the font, not of the text file that
/// generated it, so this is the only source that can answer "does the font
/// have a glyph for this character".
///
/// Reads format 4 (BMP) and format 12 (full Unicode) subtables, keyed by code
/// point. Non-BMP characters matter here: `app_search_anchor_test.dart` renders
/// U+1F44D, whose UTF-16 `codeUnitAt(0)` is the lone high surrogate 0xD83D, so
/// comparing code units against a BMP table would look up a value the format
/// cannot hold and report a false gap.
Set<int> _fontCmap(File font) {
  final bytes = font.readAsBytesSync();
  final view = ByteData.sublistView(Uint8List.fromList(bytes));

  int u16(int offset) => view.getUint16(offset);
  int u32(int offset) => view.getUint32(offset);

  final tableCount = u16(4);
  var cmapOffset = -1;
  for (var i = 0; i < tableCount; i++) {
    final record = 12 + i * 16;
    if (String.fromCharCodes(bytes.sublist(record, record + 4)) == 'cmap') {
      cmapOffset = u32(record + 8);
      break;
    }
  }
  expect(cmapOffset, isNot(-1), reason: '${font.path} has no cmap table');

  final subtableCount = u16(cmapOffset + 2);
  final format4Offsets = <int>[];
  final format12Offsets = <int>[];
  for (var i = 0; i < subtableCount; i++) {
    final record = cmapOffset + 4 + i * 8;
    final platform = u16(record);
    final offset = cmapOffset + u32(record + 4);
    final format = u16(offset);
    if (format == 4) format4Offsets.add(offset);
    // (0,x) Unicode and (3,10) Windows full Unicode are the full-range ones.
    if (format == 12 && (platform == 0 || platform == 3)) {
      format12Offsets.add(offset);
    }
  }
  expect(
    format4Offsets.isNotEmpty || format12Offsets.isNotEmpty,
    isTrue,
    reason: '${font.path} has no character map this reader understands',
  );

  final cmap = <int>{};

  for (final table in format4Offsets) {
    final segCountX2 = u16(table + 6);
    final segCount = segCountX2 ~/ 2;
    final endCodes = table + 14;
    final startCodes = endCodes + segCountX2 + 2;
    final idDeltas = startCodes + segCountX2;
    final idRangeOffsets = idDeltas + segCountX2;

    for (var segment = 0; segment < segCount; segment++) {
      final end = u16(endCodes + segment * 2);
      final start = u16(startCodes + segment * 2);
      if (start == 0xffff) continue;
      final delta = view.getInt16(idDeltas + segment * 2);
      final rangeOffsetAddress = idRangeOffsets + segment * 2;
      final rangeOffset = u16(rangeOffsetAddress);
      for (var code = start; code <= end; code++) {
        int glyph;
        if (rangeOffset == 0) {
          glyph = (code + delta) & 0xffff;
        } else {
          final glyphAddress =
              rangeOffsetAddress + rangeOffset + (code - start) * 2;
          if (glyphAddress + 1 >= bytes.length) continue;
          glyph = u16(glyphAddress);
          if (glyph != 0) glyph = (glyph + delta) & 0xffff;
        }
        if (glyph != 0) cmap.add(code);
      }
    }
  }

  for (final table in format12Offsets) {
    final groupCount = u32(table + 12);
    for (var group = 0; group < groupCount; group++) {
      final record = table + 16 + group * 12;
      final startChar = u32(record);
      final endChar = u32(record + 4);
      final startGlyph = u32(record + 8);
      if (startGlyph == 0) continue;
      for (var code = startChar; code <= endChar; code++) {
        cmap.add(code);
      }
    }
  }

  return cmap;
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
      // The subset holds the characters that appear in `lib/` and `test/`
      // string literals, plus ASCII and common symbols. When new copy needs a
      // character the font does not carry, that one character renders as tofu
      // in every baseline — the image still looks plausible, so nothing fails.
      // This turns that into a red test.
      //
      // Coverage is read from the OTF's own `cmap`. `subset-characters.txt` is
      // only the subsetting script's input, and it cannot stand in as proof:
      // editing the list without regenerating the font leaves the list
      // claiming characters the font lacks, and the test still passes.
      // `FontLoader.load()` registers a family; it does not check glyphs.
      final font = File('test/fonts/NotoSansSC-golden-subset.otf');
      expect(font.existsSync(), isTrue, reason: 'run from app/');
      final cmap = _fontCmap(font);

      // Noto Sans CJK stops at U+3106C and carries no emoji, so an astral
      // character cannot be covered by re-subsetting. The one in the tree
      // (U+1F44D in `app_search_anchor_test.dart`) belongs to a widget test,
      // not a golden fixture, and renders through the engine's own fallback
      // exactly as it would on a device shipping no emoji font. Requiring it
      // would be unsatisfiable, so the boundary is stated instead.
      const astralUnreachable = 0x10000;

      final uncovered = <int>{};
      for (final rune in _stringLiteralRunes(['lib', 'test'])) {
        if (rune > 0x7f && rune < astralUnreachable && !cmap.contains(rune)) {
          uncovered.add(rune);
        }
      }
      expect(
        uncovered,
        isEmpty,
        reason:
            'these characters appear in app strings but the font has no glyph '
            'for them, so they render as tofu in every baseline. Re-subset '
            'with: ${uncovered.map((r) => String.fromCharCode(r)).toList()}',
      );

      // The list is the subsetting script's input, so it must describe the same
      // character set as the font it produced; otherwise regenerating the font
      // from an updated list eventually gets skipped unnoticed.
      final listed = File('test/fonts/subset-characters.txt');
      expect(
        listed.existsSync(),
        isTrue,
        reason: 'run from app/; the character list ships beside the font',
      );
      final listedRunes = listed.readAsLinesSync().join().runes.toSet();
      expect(listedRunes.length, greaterThan(400));
      expect(
        (listedRunes.where((r) => r > 0x7f && r < astralUnreachable).toSet())
            .difference(cmap.where((r) => r > 0x7f).toSet()),
        isEmpty,
        reason:
            'subset-characters.txt lists characters the font does not contain; '
            'regenerate the OTF from the updated list',
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
