import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'utils/layout_breakpoints.dart';

/// 底部导航 / 侧边导航栏的一个目的地
///
/// 目的地索引与 [StatefulNavigationShell.currentIndex] 一一对应，切换目的地
/// 必须走 [StatefulNavigationShell.goBranch]，不能自己改 index，否则分支导航栈
/// 不会跟着变。
@immutable
final class const AppNavDestination({
  required final String label,
  required final IconData icon,
  final IconData? railIcon,
});

/// 应用的导航骨架容器
///
/// 紧凑宽度用底部 [NavigationBar]，宽屏（[LayoutSize.expanded]）换成
/// [NavigationRail]。两侧都只调 [StatefulNavigationShell.goBranch]，导航栈由
/// go_router 的 shell 分支自己维护。
final class const AppNavigationShell({
  super.key,
  required final StatefulNavigationShell navigationShell,
  required final List<AppNavDestination> destinations,
  final double? width,
}) extends StatelessWidget {
  void _goBranch(int index) {
    // 重复点当前目的地时回到该分支的根，而不是什么都不做。
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolvedWidth = width ?? MediaQuery.sizeOf(context).width;
    final useRail = LayoutSize.fromWidth(resolvedWidth) == LayoutSize.expanded;

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _goBranch,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(
                    icon: Icon(d.railIcon ?? d.icon),
                    label: Text(d.label),
                  ),
              ],
            ),
            // 分隔线随文字缩放变粗：固定 1 在高缩放下会显得过细。width 只是占位
            // 宽度，线条粗细由 thickness 决定，两者都要跟着缩放。
            VerticalDivider(
              width: MediaQuery.textScalerOf(context).scale(1),
              thickness: MediaQuery.textScalerOf(context).scale(1),
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _goBranch,
        destinations: [
          for (final d in destinations)
            NavigationDestination(icon: Icon(d.icon), label: d.label),
        ],
      ),
    );
  }
}
