import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../design/design.dart';
import '../../l10n/localization_file/app_localizations.dart';
import '../../main.dart';

enum SettingsSection() {
  player,
  appearance,
  history,
  library,
  notifications,
  advanced,
  discovery,
  channel,
}

/// 索引页里的一行：要打开的分节，加上它的本地化标签与图标。
typedef _SectionEntry = (SettingsSection section, String label, IconData icon);

/// 索引页的一个可展开/折叠分组。
typedef _SectionGroup = (String title, List<_SectionEntry> entries);

class const SettingScreen({
  super.key,
  required final ValueChanged<SettingsSection> onSectionSelected,
  final VoidCallback? onBackClick,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: onBackClick == null
            ? null
            : IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onBackClick?.call();
                },
                tooltip: l10n.back,
                icon: const Icon(AppIcons.back),
              ),
        title: Text(l10n.settingsTitle),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: $styles.insets.xs),
        children: [
          for (final (index, (title, entries)) in _groups(l10n).indexed)
            // A header that names a group with a single row only adds a layer of
            // nesting; render that row standalone instead (see
            // `SettingSectionHeader`'s documented rule).
            if (entries.length == 1) ...[
              if (index > 0) const Divider(height: 1),
              _sectionRow(l10n, entries.single),
            ] else
              ExpansionTile(
                // ListView 会回收离开缓存范围的分组；稳定的 PageStorageKey 让
                // ExpansionTile 重建后仍能恢复用户折叠/展开的状态。
                key: PageStorageKey<SettingsSection>(entries.first.$1),
                initiallyExpanded: true,
                title: Text(
                  title,
                  style: $styles.text.bodySmallBold.copyWith(
                    color: $styles.colors.onSurfaceVariant,
                  ),
                ),
                children: [
                  for (final entry in entries) _sectionRow(l10n, entry),
                ],
              ),
        ],
      ),
    );
  }

  Widget _sectionRow(AppLocalizations l10n, _SectionEntry entry) {
    final (section, label, icon) = entry;
    return Tooltip(
      message: label,
      child: ListTile(
        leading: Icon(icon, color: $styles.colors.onSurfaceVariant),
        title: Text(
          label,
          style: $styles.text.body.copyWith(color: $styles.colors.onSurface),
        ),
        trailing: Icon(
          AppIcons.chevronRight,
          color: $styles.colors.onSurfaceVariant,
        ),
        onTap: () {
          HapticFeedback.lightImpact();
          onSectionSelected(section);
        },
      ),
    );
  }
}

/// 索引页的分组。分节按「配置意图」归组，组内顺序即渲染顺序。
List<_SectionGroup> _groups(AppLocalizations l10n) => [
  (
    l10n.settingsGroupPlayback,
    [
      (SettingsSection.player, l10n.settingsPlayer, AppIcons.playCircle),
      (SettingsSection.appearance, l10n.settingsAppearance, AppIcons.palette),
    ],
  ),
  (
    l10n.settingsGroupLibrary,
    [
      (SettingsSection.history, l10n.settingsHistory, AppIcons.history),
      (SettingsSection.library, l10n.settingsLibrary, AppIcons.videoLibrary),
      (
        SettingsSection.notifications,
        l10n.settingsNotifications,
        AppIcons.notifications,
      ),
    ],
  ),
  (
    l10n.settingsGroupDiscovery,
    [
      (SettingsSection.discovery, l10n.settingsDiscovery, AppIcons.discover),
      (SettingsSection.channel, l10n.settingsChannel, AppIcons.creator),
    ],
  ),
  (
    l10n.settingsGroupOther,
    [(SettingsSection.advanced, l10n.settingsAdvanced, AppIcons.tune)],
  ),
];
