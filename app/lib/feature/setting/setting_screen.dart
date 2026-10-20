import 'package:material_ui/material_ui.dart';

import '../../l10n/localization_file/app_localizations.dart';
import '../../main.dart';

enum SettingsSection() {
  player,
  appearance,
  history,
  library,
  advanced,
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
            (
              SettingsSection.player,
              l10n.settingsPlayer,
              Icons.play_circle_outline,
            ),
            (
              SettingsSection.appearance,
              l10n.settingsAppearance,
              Icons.palette_outlined,
            ),
            (SettingsSection.history, l10n.settingsHistory, Icons.history),
            (
              SettingsSection.library,
              l10n.settingsLibrary,
              Icons.video_library_outlined,
            ),
            (SettingsSection.advanced, l10n.settingsAdvanced, Icons.tune),
          ])
            ListTile(
              leading: Icon(icon, color: $styles.colors.onSurfaceVariant),
              title: Text(
                label,
                style: $styles.text.body.copyWith(
                  color: $styles.colors.onSurface,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: $styles.colors.onSurfaceVariant,
              ),
              onTap: () => onSectionSelected(section),
            ),
        ],
      ),
    );
  }
}
