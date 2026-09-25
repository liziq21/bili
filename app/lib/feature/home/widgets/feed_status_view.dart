import 'package:material_ui/material_ui.dart';

import '../../../main.dart';

/// Feed 加载失败 / 空结果 / 功能占位的统一提示视图
class const FeedStatusView({
  super.key,
  required final IconData icon,
  required final String message,
  final String? description,
  final VoidCallback? onRetry,
}) extends StatelessWidget {
  /// 加载失败提示
  factory FeedStatusView.failure({
    Key? key,
    required String title,
    required VoidCallback onRetry,
  }) => FeedStatusView(
    key: key,
    icon: Icons.cloud_off_rounded,
    message: '$title 加载失败',
    description: '请检查网络连接后重试',
    onRetry: onRetry,
  );

  /// 空结果提示
  factory FeedStatusView.empty({Key? key, required String title}) =>
      FeedStatusView(
        key: key,
        icon: Icons.inbox_rounded,
        message: '$title 暂无内容',
      );

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: $styles.insets.sm,
        vertical: $styles.insets.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: $styles.insets.lg, color: colorScheme.outline),
          SizedBox(height: $styles.insets.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: $styles.text.bodySmallBold.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          if (description != null) ...[
            SizedBox(height: $styles.insets.xxs),
            Text(
              description!,
              textAlign: TextAlign.center,
              style: $styles.text.bodySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (onRetry != null) ...[
            SizedBox(height: $styles.insets.xs),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('重试'),
            ),
          ],
        ],
      ),
    );
  }
}

/// 卡片骨架占位，用于首屏加载
class const FeedSkeletonCard({super.key, final bool showTextLines = true})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final placeholderColor = colorScheme.surfaceContainerHighest;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: placeholderColor,
              borderRadius: BorderRadius.circular($styles.corners.md),
            ),
          ),
        ),
        if (showTextLines) ...[
          SizedBox(height: $styles.insets.xs),
          Container(
            height: $styles.insets.xs,
            decoration: BoxDecoration(
              color: placeholderColor,
              borderRadius: BorderRadius.circular($styles.corners.sm),
            ),
          ),
          SizedBox(height: $styles.insets.xxs),
          FractionallySizedBox(
            widthFactor: 0.6,
            alignment: Alignment.centerLeft,
            child: Container(
              height: $styles.insets.xs,
              decoration: BoxDecoration(
                color: placeholderColor,
                borderRadius: BorderRadius.circular($styles.corners.sm),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
