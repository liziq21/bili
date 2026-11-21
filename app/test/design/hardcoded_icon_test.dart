import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:flutter_test/flutter_test.dart';

/// G3 —— 图标单一来源（`app/docs/design-system.md` R9）。
///
/// `app/lib` 内只有 `lib/design/app_icons.dart` 可以引用 `Icons.*`；其余代码
/// 一律经 `AppIcons` 取值。扫描是纯语法的（`parseString`，不 resolve），判据
/// 按标识符名字面匹配：局部变量若叫 `Icons`，其 `Icons.foo` 会被误报。误报
/// 的方向是「逼作者用 AppIcons」，与 R9 的意图一致；反过来不会漏报。
const _allowedPath = 'design/app_icons.dart';

/// `flutter test` 的工作目录是包根。
const _libRoot = 'lib';

void main() {
  group('G3 图标单一来源门禁', () {
    late List<File> libFiles;

    setUpAll(() {
      final dir = Directory(_libRoot);
      if (!dir.existsSync()) {
        fail(
          '找不到 lib/ 目录（工作目录 ${Directory.current.path}）。'
          '门禁必须以包根为工作目录运行。',
        );
      }
      libFiles =
          dir
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path));
      if (libFiles.isEmpty) fail('lib/ 下没有 .dart 文件，扫描没有覆盖任何代码。');
    });

    test('lib/ 下除 app_icons.dart 外不得引用 Icons', () {
      final violations = <String>[];
      var iconsFileScanned = false;

      for (final file in libFiles) {
        final relative = file.path
            .substring(_libRoot.length + 1)
            .replaceAll(r'\', '/');
        final inIconsFile = relative == _allowedPath;
        if (inIconsFile) iconsFileScanned = true;

        final result = parseString(
          content: file.readAsStringSync(),
          path: relative,
          throwIfDiagnostics: false,
        );
        if (result.errors.isNotEmpty && result.unit.declarations.isEmpty) {
          violations.add('$relative: 解析失败，${result.errors.first.message}');
          continue;
        }

        final visitor = _IconVisitor(result.lineInfo, inIconsFile: inIconsFile);
        for (final hit in visitor.hitsIn(result.unit)) {
          violations.add(
            '$relative:${hit.line}:${hit.column}  ${hit.description}',
          );
        }
      }

      expect(
        iconsFileScanned,
        isTrue,
        reason:
            '白名单文件 lib/$_allowedPath 必须真的被扫到，'
            '否则「内容规则」是空转的',
      );
      expect(
        violations,
        isEmpty,
        reason:
            'R9 规定 app/lib 内只有 lib/$_allowedPath 允许引用 Icons。'
            '改用 AppIcons 中对应角色的常量；缺角色时先加 AppIcons。'
            '\n违规：\n${violations.join('\n')}',
      );
    });

    test('门禁本身能报出违规（探针自检）', () {
      const probeSource = '''
import 'package:flutter/material.dart';
class A {
  final a = Icons.add;
  Widget build() => Icon(Icons.add_rounded);
  Widget adaptive() => Icon(Icons.adaptive.arrow_back);
  void f() {
    final c = Icons.check;
    print(c);
  }
}
''';
      final result = parseString(
        content: probeSource,
        path: 'probe.dart',
        throwIfDiagnostics: false,
      );
      final flagged = _IconVisitor(
        result.lineInfo,
        inIconsFile: false,
      ).hitsIn(result.unit).map((h) => h.description).toList();

      expect(flagged, hasLength(4), reason: '实际：$flagged');
      expect(flagged, everyElement(contains('Icons')));
      expect(
        flagged.where((s) => s.contains('Icons.adaptive')).length,
        1,
        reason: '`Icons.adaptive.*` 也是 Icons 引用，不能漏报',
      );
    });

    test('白名单文件里只有 static const IconData 字段可以引用 Icons', () {
      const source = '''
import 'package:flutter/material.dart';
class Icons2 {
  static const IconData ok = Icons.add;
  static final IconData notConst = Icons.check;
  IconData get bad => Icons.close;
  void f() {
    const IconData local = Icons.copy;
    print(local);
  }
}
''';
      final result = parseString(
        content: source,
        path: 'icons_probe.dart',
        throwIfDiagnostics: false,
      );
      final flagged = _IconVisitor(
        result.lineInfo,
        inIconsFile: true,
      ).hitsIn(result.unit).map((h) => h.description).toList();

      expect(
        flagged,
        hasLength(3),
        reason:
            'ok（static const IconData 字段）放行；notConst（非 const）、'
            'bad（getter）、local（函数内局部 const）须报出。实际：$flagged',
      );
      expect(flagged, everyElement(contains('Icons')));
    });
  });
}

final class _Hit(final int line, final int column, final String description);

/// 收集 `Icons.*` 引用。`inIconsFile` 为真时只放行
/// 「`static const IconData` 字段的初始值」这一处，其余位置一律报出。
class _IconVisitor(final LineInfo _lineInfo, {required final bool inIconsFile})
    extends RecursiveAstVisitor<void> {
  final List<_Hit> _hits = [];

  List<_Hit> hitsIn(CompilationUnit unit) {
    unit.accept(this);
    return List.unmodifiable(_hits);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _check(node, node.prefix.name);
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    final target = node.target;
    if (target is SimpleIdentifier) _check(node, target.name);
    super.visitPropertyAccess(node);
  }

  void _check(AstNode node, String receiver) {
    if (receiver != 'Icons') return;
    if (inIconsFile && _isAllowedIconField(node)) return;
    final offset = node.offset;
    final location = _lineInfo.getLocation(offset);
    _hits.add(
      _Hit(
        location.lineNumber,
        location.columnNumber,
        '引用了 Icons：${node.toSource()}',
      ),
    );
  }

  /// 只放行 `static const IconData name = Icons.x;` 这一种位置。
  static bool _isAllowedIconField(AstNode node) {
    final declaration = node.parent;
    if (declaration is! VariableDeclaration) return false;
    if (declaration.initializer != node) return false;
    final list = declaration.parent;
    if (list is! VariableDeclarationList) return false;
    if (!list.isConst) return false;
    final type = list.type;
    if (type == null || type.toSource() != 'IconData') return false;
    final field = list.parent;
    return field is FieldDeclaration && field.isStatic;
  }
}
