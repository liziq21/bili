import 'package:material_ui/material_ui.dart';

import '../../../l10n/localization_file/app_localizations.dart';
import '../../../main.dart';
import '../feed_state.dart';

/// 一个频道分组的头部：频道名 + 未读数 + 展开/收起 + 全部已读。
///
/// 条目不由本组件持有：[FeedScreen] 把展开的条目摊平成同一个列表逐行构建，
/// 收起时这些行根本不进树，而不是建出来再隐藏。
class const FeedChannelHeader({
  super.key,
  required final FeedChannelGroup group,
  required final bool expanded,
  required final VoidCallback onToggle,
  required final VoidCallback onMarkChannelRead,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final tooltip = expanded
        ? (l10n?.feedCollapseChannel(group.channelName) ?? group.channelName)
        : (l10n?.feedExpandChannel(group.channelName) ?? group.channelName);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: $styles.insets.sm,
              vertical: $styles.insets.xxs,
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: tooltip,
                  onPressed: onToggle,
                  icon: AnimatedRotation(
                    turns: expanded ? 0 : -0.25,
                    duration: $styles.times.fast,
                    child: const Icon(Icons.expand_more_rounded),
                  ),
                ),
                Expanded(
                  child: Text(
                    group.channelName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: $styles.text.title2.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                if (group.hasUnread) ...[
                  UnreadBadge(
                    count: group.unreadCount,
                    label:
                        l10n?.feedUnreadCount(group.unreadCount) ??
                        '${group.unreadCount}',
                  ),
                  SizedBox(width: $styles.insets.xxs),
                  TextButton(
                    onPressed: onMarkChannelRead,
                    child: Text(l10n?.feedMarkAllRead ?? 'Mark all as read'),
                  ),
                ],
              ],
            ),
          ),
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ],
    );
  }
}

/// 未读计数角标
///
/// 只显示数字，读屏文案交给 [label]：视觉上仍是紧凑的数字块，语义是
/// 「3 条未读」。
class const UnreadBadge({
  super.key,
  required final int count,
  required final String label,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      label: label,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: $styles.insets.xs,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular($styles.corners.sm),
        ),
        child: Text(
          '$count',
          style: $styles.text.bodySmall.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}
