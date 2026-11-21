import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../design/design.dart';
import '../../l10n/localization_file/app_localizations.dart';
import '../../main.dart';
import '../video/danmaku/danmaku_settings_screen.dart';

/// 高级设置：低频但确实可用的入口与维护动作。
///
/// 这里只放两件事——弹幕设置入口（播放器之外的第二条路径，免得只能在某个
/// 视频里才找得到）与内存图片缓存的清理。没有磁盘缓存清理：仓库没有
/// `flutter_cache_manager` 依赖，能清的就只有内存里的解码图。
class const AdvancedSettingsScreen({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsAdvanced)),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: $styles.insets.xs),
        children: [
          ListTile(
            leading: const Icon(AppIcons.danmakuOn),
            title: Text(l10n.danmakuSettingsTitle),
            subtitle: Text(l10n.danmakuSettingsSubtitle),
            trailing: const Icon(AppIcons.chevronRight),
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const DanmakuSettingsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(AppIcons.deleteSweep),
            title: Text(l10n.clearImageCache),
            subtitle: Text(l10n.clearImageCacheSubtitle),
            onTap: () {
              HapticFeedback.selectionClick();
              // 先取 messenger：清缓存后列表会重建，发起调用的 context 可能
              // 已经不在树里。
              final messenger = ScaffoldMessenger.maybeOf(context);
              PaintingBinding.instance.imageCache
                ..clear()
                ..clearLiveImages();
              messenger?.showSnackBar(
                SnackBar(
                  content: Text(l10n.imageCacheCleared),
                  duration: $styles.times.fast,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
