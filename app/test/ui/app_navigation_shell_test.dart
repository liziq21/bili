import 'package:app/design/design.dart';
import 'package:app/ui/common/app_navigation_shell.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// 用真实的 go_router 搭一个两分支外壳：分支 0 有根页与子页，
/// 分支 1 有根页。这样「重复点按」发生在子页上，才能验证 CodeRabbit 指出的
/// 缺陷——重复点按时若先导航回分支根，回调就作用在用户已被带离的页面上。
void main() {
  testWidgets('reselect with a callback does not reset the branch', (
    tester,
  ) async {
    var reselected = 0;
    final branch1Key = GlobalKey<NavigatorState>(debugLabel: 'branch1');

    final router = GoRouter(
      initialLocation: '/home/detail',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => AppNavigationShell(
            // 紧凑宽度：底部导航栏
            width: 400,
            navigationShell: navigationShell,
            destinations: [
              const AppNavDestination(
                label: '发现',
                icon: AppIcons.discover,
                selectedIcon: AppIcons.discoverSelected,
              ),
              AppNavDestination(
                label: '搜索',
                icon: AppIcons.search,
                selectedIcon: AppIcons.searchSelected,
                onReselect: () => reselected++,
              ),
            ],
          ),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, state) =>
                      const Scaffold(body: Text('home root')),
                ),
                GoRoute(
                  path: '/home/detail',
                  builder: (context, state) =>
                      const Scaffold(body: Text('home detail')),
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: branch1Key,
              routes: [
                GoRoute(
                  path: '/search',
                  builder: (context, state) =>
                      const Scaffold(body: Text('search root')),
                ),
                GoRoute(
                  path: '/search/result',
                  builder: (context, state) =>
                      const Scaffold(body: Text('search result')),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    // 先切到搜索分支，再推进到它的子页。缺陷就发生在这个位置：
    // 重复点按时若先导航回分支根，用户已被带离搜索结果页。
    await tester.tap(find.text('搜索'));
    await tester.pumpAndSettle();
    router.go('/search/result');
    await tester.pumpAndSettle();
    expect(find.text('search result'), findsOneWidget);

    await tester.tap(find.text('搜索'));
    await tester.pumpAndSettle();

    // 回调必须执行，且页面不能被重置回分支根。
    expect(reselected, 1);
    expect(find.text('search result'), findsOneWidget);
  });

  testWidgets('reselect without a callback returns to the branch root', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/home/detail',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => AppNavigationShell(
            width: 400,
            navigationShell: navigationShell,
            destinations: const [
              AppNavDestination(
                label: '发现',
                icon: AppIcons.discover,
                selectedIcon: AppIcons.discoverSelected,
              ),
              AppNavDestination(
                label: '搜索',
                icon: AppIcons.search,
                selectedIcon: AppIcons.searchSelected,
              ),
            ],
          ),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, state) =>
                      const Scaffold(body: Text('home root')),
                ),
                GoRoute(
                  path: '/home/detail',
                  builder: (context, state) =>
                      const Scaffold(body: Text('home detail')),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/search',
                  builder: (context, state) =>
                      const Scaffold(body: Text('search root')),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('home detail'), findsOneWidget);

    // 发现没有 onReselect：重复点按应回到分支根。
    await tester.tap(find.text('发现'));
    await tester.pumpAndSettle();

    expect(find.text('home detail'), findsNothing);
    expect(find.text('home root'), findsOneWidget);
  });

  // R10：未选中目的地渲染空心图标，选中目的地渲染实心图标。底部导航与侧边
  // 导航都必须遵守——只断言一个壳层会漏掉另一条渲染路径。
  for (final (width, description) in [
    (400.0, 'bottom navigation'),
    (1200.0, 'rail'),
  ]) {
    testWidgets('selected destination uses selectedIcon ($description)', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) => AppNavigationShell(
              width: width,
              navigationShell: navigationShell,
              destinations: const [
                AppNavDestination(
                  label: '发现',
                  icon: AppIcons.discover,
                  selectedIcon: AppIcons.discoverSelected,
                ),
                AppNavDestination(
                  label: '我的',
                  icon: AppIcons.profile,
                  selectedIcon: AppIcons.profileSelected,
                ),
              ],
            ),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/home',
                    builder: (context, state) =>
                        const Scaffold(body: Text('home root')),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/mine',
                    builder: (context, state) =>
                        const Scaffold(body: Text('mine root')),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.byIcon(AppIcons.discoverSelected), findsOneWidget);
      expect(find.byIcon(AppIcons.discover), findsNothing);
      expect(find.byIcon(AppIcons.profile), findsOneWidget);
      expect(find.byIcon(AppIcons.profileSelected), findsNothing);

      await tester.tap(find.text('我的'));
      await tester.pumpAndSettle();

      expect(find.byIcon(AppIcons.profileSelected), findsOneWidget);
      expect(find.byIcon(AppIcons.profile), findsNothing);
      expect(find.byIcon(AppIcons.discover), findsOneWidget);
      expect(find.byIcon(AppIcons.discoverSelected), findsNothing);
    });
  }
}
