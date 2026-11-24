import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:material_ui/material_ui.dart';

import '../../design/design.dart';
import '../../l10n/localization_file/app_localizations.dart';
import '../../l10n/localization_file/app_localizations_zh.dart';
import '../../main.dart';
import '../video/player/playback_error.dart';
import '../video/player/playback_error_label.dart';

/// 直播播放器失败覆盖层：本地化错误分类 + 重试。
///
/// 不接收异常原文：直播地址带 `sign`/`expires`/`trid` 等时效签名参数，上屏
/// 等于把它们暴露进截图、录屏与崩溃报告；原文由播放控制器写日志。
class const LivePlaybackErrorOverlay({
  super.key,
  required final PlaybackErrorCategory category,
  required final VoidCallback onRetry,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    return ColoredBox(
      color: $styles.colors.scrim.withValues(alpha: 0.72),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.error, size: 32, color: $styles.colors.onScrim),
            const Gap(8),
            Text(
              playbackErrorCategoryLabel(l10n, category),
              style: $styles.text.body.copyWith(color: $styles.colors.onScrim),
              textAlign: TextAlign.center,
            ),
            const Gap(12),
            FilledButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                onRetry();
              },
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
