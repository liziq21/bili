import 'package:material_ui/material_ui.dart';

import '../../l10n/localization_file/app_localizations.dart';
import '../../main.dart';

class const AppearanceSettingsScreen({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsAppearance)),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: $styles.insets.xs),
        children: [
          _placeholderTile(
            icon: Icons.palette_outlined,
            title: l10n.appearanceTheme,
          ),
          _placeholderTile(
            icon: Icons.brightness_6_outlined,
            title: l10n.appearanceNightMode,
          ),
          _placeholderTile(
            icon: Icons.remove_red_eye_outlined,
            title: l10n.appearanceEyeComfort,
          ),
        ],
      ),
    );
  }
}

Widget _placeholderTile({required IconData icon, required String title}) {
  return ListTile(
    leading: Icon(icon, color: $styles.colors.onSurfaceVariant),
    title: Text(title, style: $styles.text.body),
    trailing: Icon(Icons.chevron_right, color: $styles.colors.onSurfaceVariant),
    onTap: () {},
  );
}
