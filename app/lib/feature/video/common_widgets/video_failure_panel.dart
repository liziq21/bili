import 'dart:math' as math;

import 'package:gap/gap.dart';
import 'package:material_ui/material_ui.dart';

import '../../../design/design.dart';
import '../../../main.dart';

/// 详情 / 评论面板的失败态：图标 + 一句说明 + 可选重试。
///
/// 面板在矮横屏里可能只剩一百多 dp，居中且不可滚动的 `Column` 会把重试按钮
/// 推出可视区，用户就再也点不到它。空间够时仍居中，不够时可纵向滚动。
class const VideoFailurePanel({
  super.key,
  required final String message,
  required final String retryLabel,
  final VoidCallback? onRetry,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // `$styles` 是全局静态，本身不订阅主题；本面板没有状态变化可触发重建，
    // 不显式依赖 Theme 的话，切主题后错误文字会留着旧色板（亮色错误色压
    // 暗色底只有 1.47:1）。
    Theme.of(context);
    final padding = $styles.insets.lg;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          AppIcons.cloudOff,
          size: $styles.insets.lg,
          color: $styles.colors.onSurfaceVariant,
        ),
        Gap($styles.insets.xs),
        Text(
          message,
          textAlign: TextAlign.center,
          style: $styles.text.body.copyWith(color: $styles.colors.errorText),
        ),
        if (onRetry != null) ...[
          Gap($styles.insets.sm),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(AppIcons.refresh),
            label: Text(retryLabel),
          ),
        ],
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: constraints.hasBoundedHeight
            ? ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: math.max(0, constraints.maxHeight - padding * 2),
                ),
                child: Center(child: content),
              )
            : Center(child: content),
      ),
    );
  }
}
