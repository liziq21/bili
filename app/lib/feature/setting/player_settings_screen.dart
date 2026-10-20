import 'package:material_ui/material_ui.dart';

import '../../l10n/localization_file/app_localizations.dart';

class const PlayerSettingsScreen({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.settingsPlayer)),
      body: const SizedBox.shrink(),
    );
  }
}
