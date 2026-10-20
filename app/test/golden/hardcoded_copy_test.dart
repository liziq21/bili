import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

/// 用户可见文案不得硬编码在代码里。
///
/// `golden_font_contract_test.dart` 已经断言「字面量里的每个字符都必须有
/// 字形」，但那只在**新字**上拦截：已经进过子集的旧字写在哪里都能过。要让
/// 「加中文文案 = 改 ARB」成为默认行为而不是靠人记得，规则本身必须能执行。
///
/// 判据是「`app/lib` 下非生成的 Dart 源文件里不得出现非 ASCII 字符串
/// 字面量」。三点说明：
///
///  * 日志与错误类可以硬编码**英文**，无需豁免。ASCII 天然满足这条断言，
///    所以例外不体现为 ignore 注释或白名单 —— 那类机制总会变成垃圾场。
///  * 生成目录 `app/lib/l10n/localization_file/` 整体排除：ARB 的中文值经
///    `flutter gen-l10n` 落在这里，是文案的**存放处**而非硬编码处。排除整
///    个目录而不是逐条 ignore，规则才不会退化成例外清单。
///  * 只扫字符串字面量与插值片段，不扫注释。注释与文档不受限，这条规则与
///    `AGENTS.md` 的 Language Flexibility 段一致。
///
/// 迁移完成后新增中文文案只需改 ARB：这里扫不到 `app/lib` 的手写代码，字体
/// 子集那边的新字由 `generate_subset_characters.py` 从生成产物自动收进。
void main() {
  group('hardcoded copy', () {
    test('lib sources carry no non-ASCII string literals', () {
      final offenders = <String, Set<int>>{};
      final excludedDirs = {'lib/l10n/localization_file'};

      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final path = entity.path.replaceAll(r'\', '/');
        if (excludedDirs.any(path.startsWith)) continue;

        final result = parseString(
          content: entity.readAsStringSync(),
          path: entity.path,
          throwIfDiagnostics: false,
        );
        final runes = <int>{};
        result.unit.accept(_RuneCollector(runes));
        final nonAscii = runes.where((r) => r > 0x7f).toSet();
        if (nonAscii.isNotEmpty) offenders[path] = nonAscii;
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'user-visible copy must live in app/lib/l10n/app_.arb, not in '
            'string literals. Move these literals to ARB keys and read them '
            'via AppLocalizations.of(context). Comments and documentation are '
            'unrestricted. Generated localization files are excluded because '
            'the ARB values are their source. Files and characters:\n'
            '${offenders.entries.map((e) => '  ${e.key}: '
                '${e.value.map((r) => String.fromCharCode(r)).join()}').join('\n')}',
      );
    });

    test('the scan is not vacuous', () {
      // 排除逻辑走路径前缀匹配，写宽了（例如 `lib/`）会让整棵 lib 被排除，
      // 用例全绿而什么都没扫。这里断言扫描确实覆盖到了手写源文件，
      // 并且排除目录确实是 gen-l10n 的产物目录而非拼错的路径。
      final scanned = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .map((f) => f.path.replaceAll(r'\', '/'))
          .toList();

      final generated = scanned
          .where((p) => p.startsWith('lib/l10n/localization_file'))
          .toList();
      expect(
        generated,
        isNotEmpty,
        reason: 'the exempted path must be the real gen-l10n output directory',
      );
      expect(
        generated.any((p) => p.endsWith('app_localizations_zh.dart')),
        isTrue,
        reason: 'gen-l10n output is missing; the exemption may be stale',
      );

      final handWritten = scanned
          .where((p) => !p.startsWith('lib/l10n/localization_file'))
          .toList();
      expect(
        handWritten.length,
        greaterThan(50),
        reason:
            'only ${handWritten.length} hand-written files were scanned; a '
            'broadened exclusion prefix would leave the rule vacuous',
      );
    });
  });
}

/// 收集所有非注释字符串字面量与插值片段中的码位。
///
/// ignore: use_declaring_parameters
class _RuneCollector(this._sink) extends RecursiveAstVisitor<dynamic> {
  final Set<int> _sink;

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    _sink.addAll(node.value.runes);
    super.visitSimpleStringLiteral(node);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    for (final element in node.elements) {
      if (element is InterpolationString) {
        _sink.addAll(element.value.runes);
      }
    }
    super.visitStringInterpolation(node);
  }
}
