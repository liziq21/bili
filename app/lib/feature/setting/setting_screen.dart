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

class const SettingScreen({
  super.key,
  required final ValueChanged<SettingsSection> onSectionSelected,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: $styles.insets.xs),
        children: [
          for (final (section, label, icon) in [
            (SettingsSection.player, l10n.settingsPlayer, AppIcons.playCircle),
            (
              SettingsSection.appearance,
              l10n.settingsAppearance,
              AppIcons.palette,
            ),
            (SettingsSection.history, l10n.settingsHistory, AppIcons.history),
            (
              SettingsSection.library,
              l10n.settingsLibrary,
              AppIcons.videoLibrary,
            ),
            (
              SettingsSection.notifications,
              l10n.settingsNotifications,
              AppIcons.notifications,
            ),
            (SettingsSection.advanced, l10n.settingsAdvanced, AppIcons.tune),
            (SettingsSection.discovery, l10n.settingsDiscovery, AppIcons.home),
            (SettingsSection.channel, l10n.settingsChannel, AppIcons.creator),
          ])
            Tooltip(
              message: label,
              child: ListTile(
                leading: Icon(icon, color: $styles.colors.onSurfaceVariant),
                title: Text(
                  label,
                  style: $styles.text.body.copyWith(
                    color: $styles.colors.onSurface,
                  ),
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
            ),
        ],
      ),
    );
  }
}
