import 'package:app/feature/search/app_search_anchor.dart';
import 'package:app/routing/search_focus_controller.dart';
import 'package:flutter_test/flutter_test.dart';
// 必须用 material_ui 而不是 flutter/material：SearchAnchor 内部查找的是
// material_ui 自己的 MaterialLocalizations 类型。与 app_search_anchor_test.dart
// 同一原因，这里不重复解释。
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

/// 本文件测的是「底栏重复点搜索把焦点交回输入框」这条链路的注册端。
///
/// 聚焦入口已从顶层可变闭包改为 [SearchFocusController]（由
/// [ChangeNotifierProvider] 注入）。覆盖仍拆成两层：
///   1. [AppSearchAnchor] 在 initState 注册、dispose 注销、didUpdateWidget 换绑，
///      这是实际往控制器里写值的唯一生产端；
///   2. [SearchFocusController.requestFocus] 在无人注册时静默返回——重复点搜索
///      发生在搜索页挂载前时必须不抛。
///
/// 控制器自身的语义单测见 `search_focus_controller_test.dart`。

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
      await tester.pump();

      expect(log.calls, hasLength(1));
      expect(log.isRegistered, isTrue);
    });

    testWidgets('unregisters on dispose', (tester) async {
      final log = FocusRegistrationLog();
      await tester.pumpWidget(buildAnchorWithRegistration(log));
      await tester.pump();
      expect(log.calls, hasLength(1));

      // 换成一个不含 anchor 的树即触发 dispose。
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pump();

      expect(log.calls, hasLength(2));
      expect(log.isRegistered, isFalse);
    });

    testWidgets('registers again after a remount', (tester) async {
      final log = FocusRegistrationLog();
      await tester.pumpWidget(buildAnchorWithRegistration(log));
      await tester.pump();
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pump();

      await tester.pumpWidget(buildAnchorWithRegistration(log));
      await tester.pump();

      expect(log.calls, hasLength(3));
      expect(log.isRegistered, isTrue);
    });

    testWidgets('rebinds when the registration callback changes', (
      tester,
    ) async {
      final first = FocusRegistrationLog();
      final second = FocusRegistrationLog();

      await tester.pumpWidget(buildAnchorWithRegistration(first));
      await tester.pump();
      expect(first.calls, hasLength(1));

      // 同一位置换挂载点、换注册回调，走 didUpdateWidget 分支。
      await tester.pumpWidget(buildAnchorWithRegistration(second));
      await tester.pump();

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
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('the registered entry opens the search view', (tester) async {
      final log = FocusRegistrationLog();
      await tester.pumpWidget(buildAnchorWithRegistration(log));
      await tester.pump();

      // 注册进来的函数正是 focusInput：调用后把搜索视图这条路由推进来。
      // 断言路由数而非 SearchBar 个数：anchor 自身也含一个 SearchBar，
      // 打开的视图里另有一个，按类型计数分不清「视图有没有被推进」。
      final routesBefore = tester
          .widgetList<SearchBar>(find.byType(SearchBar))
          .length;
      log.current!();
      await tester.pump();

      final searchBarsAfterOpen = tester
          .widgetList<SearchBar>(find.byType(SearchBar))
          .length;
      expect(searchBarsAfterOpen, greaterThan(routesBefore));

      // 再次调用时，由于搜索视图已经处于打开状态，不会重复推进新的搜索视图
      log.current!();
      await tester.pump();

      expect(
        tester.widgetList<SearchBar>(find.byType(SearchBar)).length,
        equals(searchBarsAfterOpen),
      );
    });

    testWidgets(
      'the registered entry re-shows the keyboard when the view is open',
      (tester) async {
        final log = FocusRegistrationLog();
        await tester.pumpWidget(buildAnchorWithRegistration(log));
        await tester.pump();

        // 第一次点按打开搜索视图，视图内输入框因 autoFocus 获得焦点并唤起键盘。
        log.current!();
        await tester.pumpAndSettle();
        expect(tester.testTextInput.isVisible, isTrue);

        // 模拟 Android 返回键 / 下滑手势收起输入法：只隐藏键盘，焦点仍留在
        // 视图输入框上（与真机一致）。
        tester.testTextInput.hide();
        await tester.pump();
        expect(tester.testTextInput.isVisible, isFalse);

        // 再次点按底栏搜索：视图已展开，仍应把键盘唤回。
        log.current!();
        await tester.pump();
        expect(tester.testTextInput.isVisible, isTrue);
      },
    );

    testWidgets('the registered entry is inert after dispose', (tester) async {
      final log = FocusRegistrationLog();
      await tester.pumpWidget(buildAnchorWithRegistration(log));
      await tester.pump();

      // 留住销毁前那个函数：它必须不能打到已销毁的 controller。
      final stale = log.current!;
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pump();

      stale();
      await tester.pump();

      expect(tester.takeException(), isNull);
      // 销毁后调用旧函数不得把已销毁的 controller 推回来。
      expect(find.byType(AppSearchAnchor), findsNothing);
    });
  });

  group('SearchFocusController requestFocus', () {
    test('does not throw when no search screen has registered', () {
      // 控制器尚未登记回调，重复点搜索发生在搜索页挂载前，此时必须静默。
      expect(SearchFocusController().requestFocus, returnsNormally);
    });

    testWidgets('router injects one controller shared by nav bar and branch', (
      tester,
    ) async {
      // 底栏目的地的 onReselect 与搜索分支必须读到同一个 SearchFocusController，
      // 否则点按触发的聚焦永远不会到达输入框。
      late BuildContext navContext;
      late BuildContext branchContext;
      final controller = SearchFocusController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        ChangeNotifierProvider<SearchFocusController>.value(
          value: controller,
          child: Builder(
            builder: (outer) {
              navContext = outer;
              return Builder(
                builder: (inner) {
                  branchContext = inner;
                  return const SizedBox.shrink();
                },
              );
            },
          ),
        ),
      );

      expect(
        identical(
          navContext.read<SearchFocusController>(),
          branchContext.read<SearchFocusController>(),
        ),
        isTrue,
      );
    });
  });
}

void _noop(String _) {}
