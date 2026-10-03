import 'package:material_ui/material_ui.dart';

import '../../../main.dart';

/// Feed 区块标题（单行紧凑形态）
class const FeedSectionHeader({
  super.key,
  required final String title,
  required final IconData icon,
  final Color? iconColor,
  final Widget? trailing,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // 单行形态：标题与副标题并排，右侧留给可选的「全部 ›」入口。
    // 原先的两行竖排（图标 + 标题 + 副标题）在一个 Feed 一屏的布局里占掉三行高度，
    // 而副标题「XX 推荐内容 / XX 正在直播」表达的是当前数据源，筛选栏已经标出来了。
    return Padding(
      padding: EdgeInsets.fromLTRB(
        $styles.insets.sm,
        $styles.insets.sm,
        $styles.insets.sm,
        $styles.insets.xs,
      ),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.only(right: $styles.insets.xs),
            child: Icon(
              icon,
              size: 18,
              color: iconColor ?? colorScheme.primary,
            ),
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: $styles.text.bodyBold.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
