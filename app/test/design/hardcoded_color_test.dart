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
/// 判据是闭合的，只有两条：
/// ① 构造路径按 `.` 分段后含 `Color` 段——覆盖 `Color(0x…)`、
///    `Color.fromARGB(…)`、`ui.Color(0x…)`、`Color.new(0x…)` 全部形态，
///    新增构造器不需要改这里。
/// ② 路径末段不是 `Color` 的静态方法（`lerp` / `lerpColor` / `parse`）——
///    那三个接收 token 做插值或解析，属规范允许的操作。
/// Dart 把颜色构造表达成三种 AST 节点（带 const 的实例创建、不带 const 的
/// 方法调用、点简写调用），三者都只需先把「构造路径」拼出来再走同一条判据。
///
/// 扫描是纯语法的（`parseString`，不 resolve），判据按标识符名字面匹配：
/// 局部变量若叫 `Colors`，其 `Colors.foo` 会被误报。误报的方向是「逼
/// 作者用 token」，与 R1 的意图一致；反过来不会漏报。
///
/// 已知缺口（有意不补，补了要 resolve 而非 parse）：
/// 命名参数实参位置上的点简写。`{'k': .fromARGB(1,2,3,4)}` 的父节点是
/// `MapLiteralEntry`，那里没有类型注解，判断「实参该是什么类型」需要
/// 所属参数的类型签名，即 resolve。
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
  final h = ui.Color(0xFF123456);
  final i = Color.new(0xFF123456);
  Color j = .fromARGB(1, 2, 3, 4);
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
        hasLength(8),
        reason:
            '探针里恰好 8 处应报（Colors.grey 出现两次算两处，'
            'Colors.transparent 豁免），实际：$flagged',
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
      // 以下三种曾各自绕过门禁：导入前缀在 methodName 上、`new` 被当成
      // 非构造器排除、点简写走独立 AST 节点。
      expect(
        flagged[5],
        '直接构造颜色：ui.Color',
        reason: '导入前缀在 target 上、类型名在 methodName 上时也要覆盖',
      );
      expect(flagged[6], '直接构造颜色：Color.new', reason: 'new 是构造器，不是静态方法');
      expect(
        flagged[7],
        '直接构造颜色：Color.fromARGB',
        reason: '点简写 .fromARGB(…) 走 DotShorthandInvocation 节点',
      );
    });

    test('白名单文件里局部 const 颜色会被报出', () {
      // 函数体/widget 里的局部 `const Color x = …` 不属于规范说的「色值常量」，
      // G1 必须报出。验证 `inPaletteFile: true` 时这类位置不被放行。
      const source = '''
import 'package:flutter/material.dart';
class A {
  static const Color ok = Color(0xFF112233);
  Color get bad => Color(0xFF445566);
  void f() {
    const Color local = Color(0xFF778899);
    print(local);
  }
}
''';
      final result = parseString(
        content: source,
        path: 'palette_probe.dart',
        throwIfDiagnostics: false,
      );
      final flagged = _HardcodedColorVisitor(
        result.lineInfo,
        inPaletteFile: true,
      ).hitsIn(result.unit).map((h) => h.description).toList();

      expect(
        flagged,
        hasLength(2),
        reason:
            'ok（字段 const）应放行；bad（getter）和 local（函数内局部 const）须报出。实际：$flagged',
      );
      expect(flagged[0], contains('直接构造颜色'));
      expect(flagged[1], contains('直接构造颜色'));
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

    test('点简写覆盖 const 构造、返回值与 .new', () {
      // 三种位置/节点各自曾绕过门禁：const 走
      // DotShorthandConstructorInvocation（与前者不同节点），返回值走
      // ExpressionFunctionBody 而非 VariableDeclaration，`.new` 的成员名
      // 是 new 不能被静态方法白名单吃掉。
      const source = '''
import 'dart:ui' as ui;
class C {
  Color m() => .fromARGB(1, 2, 3, 4);
  Color get g => .fromRGBO(1, 2, 3, .5);
}
Color topLevel() => .fromARGB(1, 2, 3, 4);
void f() {
  final n = Color.new(0xFF112233);
  final a = const ui.Color.new(0xFF112233);
  final notColor = Widget.new(0xFF112233);
  final noType = .fromARGB(1, 2, 3, 4);
  const constSh = const .fromARGB(1, 2, 3, 4);
}
class Widget {
  Widget(int x);
}
''';
      final result = parseString(
        content: source,
        path: 'shorthand_probe.dart',
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
            'notColor（Widget.new 不是 Color）与 noType（无类型注解、无上下文 '
            '可判）不报；m（箭头体）、g（getter）、topLevel（顶层箭头体）各 1 '
            '条 + Color.new 1 条 + const ui.Color.new（InstanceCreationExpression）'
            '1 条 + const .fromARGB（DotShorthandConstructorInvocation）1 条，'
            '共 5 条。实际：$flagged',
      );
      expect(flagged, everyElement(contains('直接构造颜色')));
      expect(
        flagged,
        contains('直接构造颜色：Color.new'),
        reason: 'Color.new 须按「Color.new」路径报出，不能只数总数',
      );
      expect(
        flagged.where((s) => s.contains('Color.fromARGB')).length,
        2,
        reason:
            '箭头体返回值 .fromARGB 与 const .fromARGB 两条路径都必须报出，'
            '按条数断言而不是只数总数，总数相等不能掩盖漏报或误报',
      );
      expect(
        flagged.where((s) => s == '直接构造颜色：Color.new').length,
        1,
        reason: 'Color.new 只能出现一次，总数相等不能掩盖漏报或误报',
      );
    });

    test('透明色派生调用会报出，单独用 transparent 不报', () {
      // 豁免的是 `Colors.transparent` 这个常量本身，不是以它为根的调用链：
      // `.withAlpha/.withOpacity/.withValues` 产出的是不透明黑，与豁免初衷相反。
      const source = '''
import 'package:flutter/material.dart';
void f() {
  final a = Colors.transparent;
  final b = Colors.transparent.withAlpha(255);
  final c = Colors.transparent.withOpacity(1);
  final d = Colors.transparent.withValues(alpha: 1);
  final e = material.Colors.transparent;
  final g = material.Colors.transparent.withAlpha(255);
}
''';
      final result = parseString(
        content: source,
        path: 'transparent_probe.dart',
        throwIfDiagnostics: false,
      );
      final flagged = _HardcodedColorVisitor(
        result.lineInfo,
        inPaletteFile: false,
      ).hitsIn(result.unit).map((h) => h.description).toList();

      expect(
        flagged,
        hasLength(4),
        reason:
            'a 与 e（单独用 transparent，含导入前缀）豁免；'
            'b/c/d/g 四个派生调用应报。实际：$flagged',
      );
    });

    test('可空类型注解与块函数体 return 的点简写会被报出', () {
      // `Color?` 可空注解：`toSource()` 渲染为 `Color?`，旧实现按 `.` 分段
      // 后含 `Color?` 不含 `Color`，整条绕过。块体 `return .fromARGB(…)`
      // 父节点是 `ReturnStatement`，旧实现只认 `VariableDeclaration` 与
      // `ExpressionFunctionBody`，同样绕过。两类都须报出。
      const source = '''
import 'dart:ui';
class A {
  Color? nullableArrow() => .fromARGB(1, 2, 3, 4);
  Color? nullableBlock() {
    return .fromARGB(1, 2, 3, 4);
  }
  Color blockBody() {
    if (true) {
      return .fromARGB(1, 2, 3, 4);
    }
    return .fromARGB(1, 2, 3, 4);
  }
  void closureInMethod() {
    final plain = () { return .fromARGB(1, 2, 3, 4); };
    plain();
  }
  int intBlock() {
    return 1;
  }
}
''';
      final result = parseString(
        content: source,
        path: 'nullable_block_probe.dart',
        throwIfDiagnostics: false,
      );
      final flagged = _HardcodedColorVisitor(
        result.lineInfo,
        inPaletteFile: false,
      ).hitsIn(result.unit).map((h) => h.description).toList();

      expect(
        flagged,
        hasLength(4),
        reason:
            'nullableArrow（可空箭头体）、nullableBlock（可空块体 return）、'
            'blockBody 两个 return（非可空块体）、closureInMethod 里的 '
            'Color Function() 块体 return 共 5 处位置，但 closureInMethod '
            '的闭包没有声明的返回类型注解（analyzer 13.3.0 实测读到 '
            'FunctionExpression 即不可判，不报），实际报出 4 处。'
            'plain 闭包与 intBlock 不报。实际：$flagged',
      );
      expect(flagged, everyElement(contains('直接构造颜色')));
    });

    test('白名单文件顶层 const 放行、局部 const 仍报出', () {
      // G1 允许顶层 `const Color accent = Color(0x…)`；顶层变量的声明节点是
      // TopLevelVariableDeclaration，与字段的 FieldDeclaration 并列。
      const source = '''
import 'package:flutter/material.dart';
const Color topOk = Color(0xFF112233);
class A {
  static const Color fieldOk = Color(0xFF223344);
  Color get bad => Color(0xFF445566);
  void f() {
    const Color local = Color(0xFF778899);
    print(local);
  }
}
''';
      final result = parseString(
        content: source,
        path: 'palette_top_probe.dart',
        throwIfDiagnostics: false,
      );
      final flagged = _HardcodedColorVisitor(
        result.lineInfo,
        inPaletteFile: true,
      ).hitsIn(result.unit).map((h) => h.description).toList();

      expect(
        flagged,
        hasLength(2),
        reason: '顶层与字段 const 应放行；getter 与局部 const 须报出。实际：$flagged',
      );
    });

    test('Color.lerp 等静态方法调用不报（规范允许 token 插值）', () {
      const source = '''
class A {
  static Color blend(Color a, Color b) => Color.lerp(a, b, 0.5);
  static Color parseIt() => Color.parse('#FF112233');
}
''';
      final result = parseString(
        content: source,
        path: 'lerp_probe.dart',
        throwIfDiagnostics: false,
      );
      final hits = _HardcodedColorVisitor(
        result.lineInfo,
        inPaletteFile: false,
      ).hitsIn(result.unit);
      expect(hits, isEmpty, reason: '静态方法调用被误报：$hits');
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
  /// 读自声明的类型注解（`returnType` / `VariableDeclarationList.type`）
  /// 可能带可空标记（`Color?`），段里先剥掉尾部 `?` 再比较。
  static bool _mentionsColorType(String source) => source
      .split('.')
      .map((s) => s.endsWith('?') ? s.substring(0, s.length - 1) : s)
      .contains('Color');

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    // 带 const 的构造落在这里。实测 `const Color.fromRGBO(…)` 的
    // constructorName.type.toSource() 是 "Color.fromRGBO"——具名构造器折进了
    // type 的源码里，所以按分段判断而不是只比较整串。
    _checkConstructorPath(node, node.constructorName.type.toSource());
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // 不带 const 的构造落在这里，target 有三种形态：
    //   Color(0x…)        target=null, method='Color'
    //   Color.fromARGB(…)  target='Color', method='fromARGB'
    //   ui.Color(0x…)      target='ui',     method='Color'
    //   Color.new(0x…)     target='Color',  method='new'
    // 前两种之外，后两种曾被各自的判断漏掉（`ui.` 前缀不在 target 的
    // 首段里；`new` 被当成非构造器排除）。拼成完整路径后交给同一条判据。
    final target = node.target;
    _checkConstructorPath(
      node,
      target == null
          ? node.methodName.name
          : '${target.toSource()}.${node.methodName.name}',
    );
    super.visitMethodInvocation(node);
  }

  @override
  void visitDotShorthandInvocation(DotShorthandInvocation node) {
    // 点简写 `.fromARGB(…)` 是 Dart 3.10 起的新语法，走独立节点
    // （analyzer 13.3.0 实测），不接 `visitMethodInvocation`。
    // 类型来自上下文而非 target，所以先确认所在位置的上下文类型是 Color。
    final ctx = _dotShorthandContextIsColor(node);
    if (ctx) {
      _checkConstructorPath(node, 'Color.${node.memberName.name}');
    }
    super.visitDotShorthandInvocation(node);
  }

  @override
  void visitDotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation node,
  ) {
    // `const .fromARGB(…)` 走这个节点而非上一个（实测两者并存：
    // `.new(0x…)` 归前者，`const .fromARGB(…)` 归后者），必须单独接。
    if (_dotShorthandContextIsColor(node)) {
      _checkConstructorPath(node, 'Color.${node.constructorName.name}');
    }
    super.visitDotShorthandConstructorInvocation(node);
  }

  /// 点简写的类型来自上下文。它出现的位置不止变量初始化器——箭头函数
  /// 返回值（`=> .fromARGB(…)`）与块函数体里的 `return .fromARGB(…)`
  /// 同样会出现，只认 `VariableDeclaration` 会让这些写法绕过门禁。
  ///
  /// 位置与类型来源（analyzer 13.3.0 实测父链）：
  /// | 位置                        | 直接父节点               | 类型读自            |
  /// |------------------------------|---------------------------|---------------------|
  /// | 变量/字段/顶层声明初始化器   | `VariableDeclaration`     | `VariableDeclarationList.type` |
  /// | 箭头函数体返回值             | `ExpressionFunctionBody`   | 所属声明的 `returnType` |
  /// | 块函数体内 return 表达式      | `ReturnStatement`         | 所属 `FunctionBody` 的 `returnType` |
  ///
  /// 箭头体的 `ExpressionFunctionBody` 自身不持有 `returnType`（analyzer 13.3.0
  /// 实测该节点没有这个 getter），须沿父链上推到声明。块体的
  /// `ReturnStatement` 直接父是 `Block`，同样须上推到函数声明。
  /// 闭包没有自己的返回类型注解（`() => …` 与 `() { … }` 都只有
  /// 参数类型），所以读到 `FunctionExpression` 但再上一级不是带
  /// `returnType` 的 `FunctionDeclaration`/`MethodDeclaration` 时，
  /// 判定为不可判，不报。
  ///
  /// 命名参数实参（`{'k': .fromARGB(…)}`，父节点 `MapLiteralEntry`）没有
  /// 类型注解可读——`parseString` 不 resolve，拿不到所属参数的类型，故不覆盖。
  /// 该缺口记在文件头的「已知缺口」一节。
  static bool _dotShorthandContextIsColor(AstNode node) {
    switch (node.parent) {
      case VariableDeclaration(:final parent?):
        // `parent` 是 `vd.parent`（即 VariableDeclarationList，analyzer 13.3.0
        // 实测），不能再上跳一层。
        return parent is VariableDeclarationList &&
            parent.type != null &&
            _mentionsColorType(parent.type!.toSource());
      case ExpressionFunctionBody(:final parent):
        // 返回类型在「声明」上而非函数体上。方法/getter 的声明是
        // MethodDeclaration，闭包（`() => …`）没有自己的返回类型注解，
        // 它的声明还要再上一层才是带 returnType 的函数/方法声明。
        // analyzer 13.3.0 实测 `ExpressionFunctionBody` 与
        // `BlockFunctionBody` 都没有 returnType getter，只能从声明读。
        final returnType = switch (parent) {
          MethodDeclaration(:final returnType) => returnType,
          FunctionExpression(:final parent) => switch (parent) {
            FunctionDeclaration(:final returnType) => returnType,
            _ => null,
          },
          _ => null,
        };
        return returnType != null && _mentionsColorType(returnType.toSource());
      case ReturnStatement(:final parent):
        // 块体里的 `return .fromARGB(…)`：直接父是 `Block`，没有类型信息，
        // 须沿父链上推到最近的 `FunctionBody`（单层 `Block` 之外还可能
        // 隔着 `IfStatement` 的块体，analyzer 13.3.0 实测：
        // `if (true) { return …; }` 的父链是
        // ReturnStatement → Block → IfStatement → Block → 外层函数体），
        // 再上推到声明读 `returnType`。
        // 闭包（父链先碰到 `FunctionExpression`）没有声明的返回类型注解，
        // 读到 `FunctionExpression` 时返回 false（不可判，不报）；
        // 外层声明是 `Color` 的方法里，闭包体的 return 仍报出——
        // 判据读的是「所属函数体的声明」而非最外层方法，闭包自身
        // 声明不出来的返回类型注解就不可判。
        // 沿父链上推到最近的 `FunctionBody`；父链上 `Block` /
        // `IfStatement` 等中间节点的 `parent` 必非空（analyzer 13.3.0
        // 实测），直接以非可空形式走。
        AstNode? up = parent;
        while (up is! FunctionBody) {
          if (up == null || up is FunctionExpression) return false;
          up = up.parent;
        }
        final declaration = up.parent;
        final returnType = switch (declaration) {
          MethodDeclaration(:final returnType) => returnType,
          FunctionDeclaration(:final returnType) => returnType,
          _ => null,
        };
        return returnType != null && _mentionsColorType(returnType.toSource());
      default:
        return false;
    }
  }

  /// 三种构造节点的共同出口：把「构造路径」按 `.` 分段，含 `Color` 段且
  /// 末段不是静态方法时报出。
  void _checkConstructorPath(AstNode node, String path) {
    if (_isColorConstructorPath(path) && !_isAllowedColorLiteral(node.offset)) {
      _report(node.offset, '直接构造颜色：$path');
    }
  }

  /// 路径含 `Color` 段（`Color` / `ui.Color` / `material_ui.Color` 都算；
  /// `MyColor` 与 `ColorScheme` 不算），且末段不是静态方法。
  static bool _isColorConstructorPath(String path) {
    final segments = path.split('.');
    return segments.contains('Color') &&
        !_colorStaticMethods.contains(segments.last);
  }

  /// `Color` 的静态方法白名单：这些方法接收 Color 参数（通常是 token），
  /// 返回新 Color，不是硬编码颜色构造，不算 G1 违规。
  /// 注意：`from`/`fromARGB`/`fromRGBO`/`fromAlpha` 是具名构造器，
  /// 会创建字面量颜色，属于 G1 应报范围，**不在**此白名单里。
  static const _colorStaticMethods = {'lerp', 'lerpColor', 'parse'};

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    // `Colors.grey[300]` 与 `Colors.grey.shade400` 的内层都是
    // PrefixedIdentifier，所以这一处就能覆盖下标与级联两种写法。
    if (!inPaletteFile &&
        _isColorsClassRef(node.prefix) &&
        !_isExemptColorsConstant(node)) {
      _report(node.offset, '硬编码色常量：Colors.${node.identifier.name}');
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    // 带导入前缀时 `material.Colors.red` 的内层是
    // PrefixedIdentifier('material.Colors')，常量名落在外层
    // PropertyAccess 上——只接 PrefixedIdentifier 会让这种写法整条绕过门禁。
    if (!inPaletteFile &&
        _isColorsClassRef(node.target) &&
        !_isExemptColorsConstant(node)) {
      _report(node.offset, '硬编码色常量：Colors.${node.propertyName.name}');
    }
    super.visitPropertyAccess(node);
  }

  /// 豁免的判据是「`Colors.transparent` 没有被当作接收者继续调用」。
  ///
  /// 不能只判名字：`Colors.transparent.withAlpha(255)` 里的
  /// `Colors.transparent` 与裸写时是**同一个 AST 节点**，按名字判断两者
  /// 无法区分。它在派生调用里会成为 `MethodInvocation` 的 `target`
  /// （或级联的 section），所以看它有没有被当成接收者才是根因判据。
  /// 派生结果是不透明黑，与豁免初衷相反，必须报出。
  static bool _isExemptColorsConstant(AstNode node) {
    final name = switch (node) {
      PrefixedIdentifier(:final identifier) => identifier.name,
      PropertyAccess(:final propertyName) => propertyName.name,
      _ => null,
    };
    if (name != _exemptColorsConstant) return false;
    final parent = node.parent;
    return !(parent is MethodInvocation && identical(parent.target, node)) &&
        parent is! CascadeExpression;
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
    // 只放行「字段声明」（`FieldDeclaration`）里的 const 初始值；
    // 函数体里的局部 `const Color x = …`（`VariableDeclarationStatement`）
    // 不在 G1 允许清单内——规范说的是「色值常量」，局部 const 是工具
    // 函数/widget 内部细节，不能借白名单文件名绕过 G1。
    if (node.keyword?.lexeme == 'const' &&
        (node.parent is FieldDeclaration ||
            node.parent is TopLevelVariableDeclaration)) {
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
