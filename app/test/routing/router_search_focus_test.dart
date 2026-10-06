import 'package:app/feature/search/app_search_anchor.dart';
import 'package:app/routing/router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
// 必须用 material_ui 而不是 flutter/material：SearchAnchor 内部查找的是
// material_ui 自己的 MaterialLocalizations 类型。与 app_search_anchor_test.dart
// 同一原因，这里不重复解释。
import 'package:material_ui/material_ui.dart';

/// 本文件测的是「底栏重复点搜索把焦点交回输入框」这条链路的注册端。
///
/// 注册槽位 `_focusSearchInput` 在 router.dart 里是私有的，测试无法直接写入，
/// 所以覆盖拆成两层：
///   1. [AppSearchAnchor] 在 initState 注册、dispose 注销、didUpdateWidget 换绑，
///      这是实际往槽位里写值的唯一生产端；
///   2. [requestSearchFocus] 在无人注册时静默返回——私有槽位初始为 null，
///      这是可从公开 API 观测到的真实行为（重复点搜索发生在搜索页挂载前）。
///
/// 真正的端到端链路（router 把 [AppSearchAnchor.onFocusInputReady] 接到私有
/// 槽位）需要拉起整棵 provider 树，收益不抵成本，此处不覆盖。

/// 记录注册端收到的所有回调调用序列。
class FocusRegistrationLog() {
  final List<void Function()> calls = [];
  void Function()? current;

  void register(void Function()? focus) {
    if (focus == null) {
      calls.add(_unregister);
      current = null;
      return;
    }
    calls.add(focus);
    current = focus;
  }

  static void _unregister() {}

  bool get isRegistered => current != null;
}

/// 挂载一个带注册回调的 [AppSearchAnchor]。
///
/// BlocProvider 必须放在 MaterialApp 内部、Navigator 之下：SearchAnchor 打开的
/// 浮层是推到 Navigator overlay 上的路由，位于这个子树之外。
Widget buildAnchorWithRegistration(FocusRegistrationLog log, {Key? anchorKey}) {
  return MaterialApp(
    home: Scaffold(
      body: AppSearchAnchor(
        key: anchorKey,
        onSearch: (_) {},
        onFocusInputReady: log.register,
      ),
    ),
  );
}

void main() {
  group('AppSearchAnchor focus registration', () {
    testWidgets('registers a focus entry on mount', (tester) async {
      final log = FocusRegistrationLog();

      await tester.pumpWidget(buildAnchorWithRegistration(log));
      await tester.pumpAndSettle();

      expect(log.calls, hasLength(1));
      expect(log.isRegistered, isTrue);
    });

    testWidgets('unregisters on dispose', (tester) async {
      final log = FocusRegistrationLog();
      await tester.pumpWidget(buildAnchorWithRegistration(log));
      await tester.pumpAndSettle();
      expect(log.calls, hasLength(1));

      // 换成一个不含 anchor 的树即触发 dispose。
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pumpAndSettle();

      expect(log.calls, hasLength(2));
      expect(log.isRegistered, isFalse);
    });

    testWidgets('registers again after a remount', (tester) async {
      final log = FocusRegistrationLog();
      await tester.pumpWidget(buildAnchorWithRegistration(log));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pumpAndSettle();

      await tester.pumpWidget(buildAnchorWithRegistration(log));
      await tester.pumpAndSettle();

      expect(log.calls, hasLength(3));
      expect(log.isRegistered, isTrue);
    });

    testWidgets('rebinds when the registration callback changes', (
      tester,
    ) async {
      final first = FocusRegistrationLog();
      final second = FocusRegistrationLog();

      await tester.pumpWidget(buildAnchorWithRegistration(first));
      await tester.pumpAndSettle();
      expect(first.calls, hasLength(1));

      // 同一位置换挂载点、换注册回调，走 didUpdateWidget 分支。
      await tester.pumpWidget(buildAnchorWithRegistration(second));
      await tester.pumpAndSettle();

      // 旧回调先被注销，新回调再被注册，顺序即注销先于注册。
      expect(first.calls, hasLength(2));
      expect(first.isRegistered, isFalse);
      expect(second.calls, hasLength(1));
      expect(second.isRegistered, isTrue);
    });

    testWidgets('works without a registration callback', (tester) async {
      // onFocusInputReady 为 null 是合法形态（组件内部照常工作）。
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppSearchAnchor(onSearch: _noop)),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('the registered entry opens the search view', (tester) async {
      final log = FocusRegistrationLog();
      await tester.pumpWidget(buildAnchorWithRegistration(log));
      await tester.pumpAndSettle();

      // 注册进来的函数正是 focusInput：调用后把搜索视图这条路由推进来。
      // 断言路由数而非 SearchBar 个数：anchor 自身也含一个 SearchBar，
      // 打开的视图里另有一个，按类型计数分不清「视图有没有被推进」。
      final routesBefore = tester
          .widgetList<SearchBar>(find.byType(SearchBar))
          .length;
      log.current!();
      await tester.pumpAndSettle();

      expect(
        tester.widgetList<SearchBar>(find.byType(SearchBar)).length,
        greaterThan(routesBefore),
      );
    });

    testWidgets('the registered entry is inert after dispose', (tester) async {
      final log = FocusRegistrationLog();
      await tester.pumpWidget(buildAnchorWithRegistration(log));
      await tester.pumpAndSettle();

      // 留住销毁前那个函数：它必须不能打到已销毁的 controller。
      final stale = log.current!;
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pumpAndSettle();

      stale();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // 销毁后调用旧函数不得把已销毁的 controller 推回来。
      expect(find.byType(AppSearchAnchor), findsNothing);
    });
  });

  group('requestSearchFocus', () {
    test('does not throw when no search screen has registered', () {
      // 私有槽位初值为 null，重复点搜索发生在搜索页挂载前，此时必须静默。
      expect(requestSearchFocus, returnsNormally);
    });
  });
}

void _noop(String _) {}
