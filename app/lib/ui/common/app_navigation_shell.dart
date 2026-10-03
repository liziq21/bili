import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'utils/layout_breakpoints.dart';

/// 底部导航 / 侧边导航栏的一个目的地
@immutable
final class const AppNavDestination({
  /// 目的地文案，底部与侧边导航共用
  required final String label,

  /// 底部导航图标
  required final IconData icon,

  /// 侧边导航图标，留空时回落到 [icon]
  final IconData? railIcon,
});

/// 应用的导航骨架容器
final class const AppNavigationShell({
  super.key,
  required final StatefulNavigationShell navigationShell,
  required final List<AppNavDestination> destinations,

  /// 判定用宽度，缺省时取整屏宽度
  final double? width,
}) extends StatelessWidget {
  void _goBranch(int index) {
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
