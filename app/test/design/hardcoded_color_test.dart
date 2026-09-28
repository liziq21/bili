import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:flutter_test/flutter_test.dart';

/// G1 —— 禁止硬编码色（`app/docs/design-system.md` R1 / 第 4 节）。
///
/// 为什么是测试而不是 custom_lint 插件：custom_lint 最新 0.8.1 把
/// `analyzer` 钉在 `^8.0.0`，而本仓在 Dart 3.13 上解析到 13.3.0，pub
/// 求解器直接判无解；降到 8 则解析不了本仓大量使用的 primary constructor
/// 语法（`class const Foo(...)`）。门禁挂在现有 `cd app && flutter test`
/// 这一步上，零新 infra。
///
/// 实现约束来自规范：必须覆盖**完整的构造器集合**，`Color.fromRGBO` 之类
/// 漏掉即形同虚设。因此这里不枚举构造器名，而是匹配「类型名等于 Color」
/// 并接受任意具名构造器与任意导入前缀。
///
/// 扫描是纯语法的（`parseString`，不 resolve），判据按标识符名字面匹配：
/// 局部变量若叫 `Colors`，其 `Colors.foo` 会被误报。误报的方向是「逼
/// 作者用 token」，与 R1 的意图一致；反过来不会漏报。
const _allowedPath = 'design/brand_palette.dart';

/// `flutter test` 的工作目录是包根，`listSync` 返回的路径同基准。
const _libRoot = 'lib';

/// `Colors.transparent` 无语义，规范明确豁免。
const _exemptColorsConstant = 'transparent';

void main() {
  group('G1 硬编码色门禁', () {
    late List<File> libFiles;

    setUpAll(() {
      // `flutter test` 以包根（app/）为工作目录。
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

    test('lib/ 下除 brand_palette.dart 外不得出现颜色字面量', () {
      final violations = <String>[];
      var paletteScanned = false;

      for (final file in libFiles) {
        final relative = file.path
            .substring(_libRoot.length + 1)
            .replaceAll(r'\', '/');
        // 白名单文件不整文件放行：R1 同时约束它的内容，改走内容规则。
        final inPaletteFile = relative == _allowedPath;
        if (inPaletteFile) paletteScanned = true;

        final result = parseString(
          content: file.readAsStringSync(),
          path: relative,
          throwIfDiagnostics: false,
        );
        // 解析不出 AST 时文件本身就是坏的，analyze 会报，这里不重复计数。
        if (result.errors.isNotEmpty && result.unit.declarations.isEmpty) {
          violations.add('$relative: 解析失败，${result.errors.first.message}');
          continue;
        }

        final visitor = _HardcodedColorVisitor(
          result.lineInfo,
          inPaletteFile: inPaletteFile,
        );
        for (final hit in visitor.hitsIn(result.unit)) {
          violations.add(
            '$relative:${hit.line}:${hit.column}  ${hit.description}',
          );
        }
      }

      expect(
        paletteScanned,
        isTrue,
        reason:
            '白名单文件 lib/$_allowedPath 必须真的被扫到，'
            '否则「内容规则」是空转的',
      );
      expect(
        violations,
        isEmpty,
        reason:
            'R1 规定 app/lib 内只有 lib/$_allowedPath 允许颜色字面量。'
            '改用 ColorScheme / \$styles.colors 的对应角色取值。'
            '\n违规：\n${violations.join('\n')}',
      );
    });

    test('门禁本身能报出违规（探针自检）', () {
      // 探针必须先证明自己有效，否则上面那条全绿也说明不了任何事：
      // 扫描器若恒返回空，「迁移已完成」与「扫描器坏了」长得一模一样。
      const probeSource = '''
import 'package:flutter/material.dart';
void f() {
  final a = Color(0xFF123456);
  final b = Color.fromARGB(1, 2, 3, 4);
  final c = ui.Color.fromRGBO(1, 2, 3, .5);
  final d = Colors.grey[300];
  final e = Colors.grey.shade400;
  final g = Colors.transparent;
}
''';
      final result = parseString(
        content: probeSource,
        path: 'probe.dart',
        throwIfDiagnostics: false,
      );
      final flagged = _HardcodedColorVisitor(
        result.lineInfo,
        inPaletteFile: false,
      ).hitsIn(result.unit).map((h) => h.description).toList();

      expect(
        flagged,
        hasLength(5),
        reason:
            '探针里恰好 5 处应报（Colors.grey 出现两次算两处），'
            '实际：$flagged',
      );
      expect(
        flagged.first,
        '直接构造颜色：Color',
        reason: '无 const 的 Color(0x…) 走 MethodInvocation（target 为 null）',
      );
      expect(flagged[1], contains('Color.fromARGB'), reason: '具名构造器必须覆盖');
      expect(
        flagged[2],
        contains('ui.Color.fromRGBO'),
        reason: '带导入前缀的具名构造器必须覆盖',
      );
      expect(
        flagged[3],
        contains('Colors.grey'),
        reason: '下标写法 Colors.grey[300] 也要覆盖',
      );
    });

    test('const 形式的颜色构造同样会被报出', () {
      // parseString 对同一个构造会给出两种节点：带 const 的是
      // InstanceCreationExpression，不带的是 MethodInvocation。只接一种
      // 会让规则在真实代码上大面积漏报，所以两种都必须有断言。
      const source = '''
import 'package:flutter/material.dart';
class A {
  static const Color x = Color(0xFF112233);
  static const Color y = const Color.fromRGBO(1, 2, 3, .5);
  static const Color z = const ui.Color(0xFF000000);
}
''';
      final result = parseString(
        content: source,
        path: 'const_probe.dart',
        throwIfDiagnostics: false,
      );
      final flagged = _HardcodedColorVisitor(
        result.lineInfo,
        inPaletteFile: false,
      ).hitsIn(result.unit).map((h) => h.description).toList();

      expect(flagged, hasLength(3), reason: '实际：$flagged');
      expect(flagged[1], contains('Color.fromRGBO'));
      expect(flagged[2], contains('ui.Color'));
    });
  });
}

class _Hit(final int line, final int column, final String description);

/// 纯语法扫描器，行为见文件头注释。
class _HardcodedColorVisitor(
  final LineInfo _lineInfo, {
  // 声明式参数 `this.inPaletteFile` 在本 SDK 版本下被这条 lint 误报，
  // 拆成「参数 + 字段」反而同时触发更多 lint，加 ignore 是最小消法。
  // ignore: use_declaring_parameters
  required this.inPaletteFile,
}) extends RecursiveAstVisitor<void> {
  // 公开字段：外部测试调用方（探针自检）需要按名字读，不能私有化。
  final bool inPaletteFile;

  final List<_Hit> _hits = [];

  /// 白名单文件里允许出现 `Color(…)` 字面量的位置，两路（含端点 offset 区间）：
  /// ① `const` 变量/字段声明的初始值；
  /// ② 任何 `ColorScheme(…)` 构造的参数列表——R1 允许清单里「ColorScheme 构造」
  /// 的一部分，其参数就是色值。
  ///
  /// 必须先扫一遍再走主遍历——`RecursiveAstVisitor` 是单趟的，走到字面量时
  /// 还不知道它归不归这两类位置。
  final List<(int, int)> _allowedColorLiterals = [];

  List<_Hit> hitsIn(CompilationUnit unit) {
    if (inPaletteFile) {
      unit.accept(_AllowedColorLiteralCollector(_allowedColorLiterals));
    }
    unit.accept(this);
    return _hits;
  }

  /// 白名单模式下 `Color(…)` 落在允许位置时返回 `true`。
  bool _isAllowedColorLiteral(int offset) =>
      _allowedColorLiterals.any((r) => offset >= r.$1 && offset <= r.$2);

  void _report(int offset, String description) {
    final location = _lineInfo.getLocation(offset);
    _hits.add(_Hit(location.lineNumber, location.columnNumber, description));
  }

  /// `Color` / `ui.Color` / `material_ui.Color` 都算；`MyColor` 与
  /// `ColorScheme` 不算（按点分段做整段相等比较，不做子串匹配）。
  static bool _mentionsColorType(String source) =>
      source.split('.').contains('Color');

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    // 实测 `const Color.fromRGBO(…)` 的 constructorName.type.toSource()
    // 是 "Color.fromRGBO"——具名构造器折进了 type 的源码里，所以按分段
    // 判断而不是只比较整串。
    final typeSource = node.constructorName.type.toSource();
    if (_mentionsColorType(typeSource) &&
        !_isAllowedColorLiteral(node.offset)) {
      _report(node.offset, '直接构造颜色：$typeSource');
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.target;
    if (target == null) {
      if (node.methodName.name == 'Color' &&
          !_isAllowedColorLiteral(node.offset)) {
        _report(node.offset, '直接构造颜色：Color');
      }
    } else {
      final method = node.methodName.name;
      if (method != 'new' &&
          _mentionsColorType(target.toSource()) &&
          !_isAllowedColorLiteral(node.offset)) {
        _report(node.offset, '直接构造颜色：${target.toSource()}.$method');
      }
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    // `Colors.grey[300]` 与 `Colors.grey.shade400` 的内层都是
    // PrefixedIdentifier，所以这一处就能覆盖下标与级联两种写法。
    if (!inPaletteFile &&
        _isColorsClassRef(node.prefix) &&
        node.identifier.name != _exemptColorsConstant) {
      _report(node.offset, '硬编码色常量：Colors.${node.identifier.name}');
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    // 带导入前缀时 `material.Colors.red` 的内层是
    // PrefixedIdentifier('material.Colors')，常量名落在外层
    // PropertyAccess 上——只接 PrefixedIdentifier 会让这种写法整条绕过门禁。
    // 豁免判断必须放在这一层，否则 `material.Colors.transparent` 会被误报。
    if (!inPaletteFile &&
        _isColorsClassRef(node.target) &&
        node.propertyName.name != _exemptColorsConstant) {
      _report(node.offset, '硬编码色常量：Colors.${node.propertyName.name}');
    }
    super.visitPropertyAccess(node);
  }

  /// 表达式是否指向 `Colors` 这个类本身：`Colors` 或 `material.Colors`。
  static bool _isColorsClassRef(Expression? expression) => switch (expression) {
    SimpleIdentifier(name: final name) => name == 'Colors',
    // `material.Colors`：标识符那一段就是类名，前面的是导入前缀。
    PrefixedIdentifier(:final identifier) => identifier.name == 'Colors',
    _ => false,
  };
}

/// 收集白名单文件里允许出现 `Color(…)` 字面量的位置 offset 区间。
///
/// 两路：
/// ① `const` 变量/字段声明的初始值。判据是 `VariableDeclarationList` 上的
///    `const` 关键字（analyzer 13 实测：`static const Color x = Color(0x…)`
///    取 `"const"`，`static final` 取 `"final"`，无修饰符取 `null`），
///    不看声明的静态性——局部 `const` 与字段 `const` 同属规范说的「色值常量」。
/// ② 任何 `ColorScheme(…)` 构造的 offset 区间（整串 `ColorScheme(…)`）——
///    R1 允许清单里「ColorScheme 构造」的参数位置。
class _AllowedColorLiteralCollector(final List<(int, int)> _ranges)
    extends RecursiveAstVisitor<void> {
  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    if (node.keyword?.lexeme == 'const') {
      for (final variable in node.variables) {
        final initializer = variable.initializer;
        if (initializer != null) {
          _ranges.add((initializer.offset, initializer.end));
        }
      }
    }
    super.visitVariableDeclarationList(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // 不带 const 的 `ColorScheme(...)` 是 MethodInvocation（target=null，
    // methodName='ColorScheme'），带 const 时是 InstanceCreationExpression
    // （`constructorName.type.toSource()` 含 "ColorScheme"）。两路都接。
    if (node.target == null && node.methodName.name == 'ColorScheme') {
      _ranges.add((node.offset, node.end));
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.constructorName.type.toSource().split('.').last == 'ColorScheme') {
      _ranges.add((node.offset, node.end));
    }
    super.visitInstanceCreationExpression(node);
  }
}
