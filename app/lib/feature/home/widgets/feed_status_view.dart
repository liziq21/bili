import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/localization_file/app_localizations.dart';
import '../../../main.dart';

/// Feed 加载失败 / 空结果 / 功能占位的统一提示视图
class const FeedStatusView({
  super.key,
  required final IconData icon,
  required final String message,
  final String? description,
  final VoidCallback? onRetry,
  final String? failureTitle,
  final String? emptyTitle,
}) extends StatelessWidget {
  /// 加载失败提示
  factory failure({
    Key? key,
    required String title,
    required VoidCallback onRetry,
  }) => FeedStatusView(
    key: key,
    icon: Icons.cloud_off_rounded,
    message: title,
    failureTitle: title,
    onRetry: onRetry,
  );

  /// 空结果提示
  factory empty({Key? key, required String title}) => FeedStatusView(
    key: key,
    icon: Icons.inbox_rounded,
    message: title,
    emptyTitle: title,
  );

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final resolvedMessage = failureTitle != null
        ? (l10n?.sectionLoadFailed(failureTitle!) ?? '$failureTitle failed')
        : emptyTitle != null
        ? (l10n?.sectionEmpty(emptyTitle!) ?? '$emptyTitle is empty')
        : message;
    final desc = failureTitle != null
        ? (l10n?.checkNetworkRetry ?? 'Check your connection and retry')
        : description;

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
            resolvedMessage,
            textAlign: TextAlign.center,
            style: $styles.text.bodySmallBold.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          if (desc != null) ...[
            SizedBox(height: $styles.insets.xxs),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: $styles.text.bodySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (onRetry != null) ...[
            SizedBox(height: $styles.insets.xs),
            OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                onRetry!();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n?.retry ?? 'Retry'),
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
