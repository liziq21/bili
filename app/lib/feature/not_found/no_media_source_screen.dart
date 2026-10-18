import 'package:material_ui/material_ui.dart';

import '../../l10n/localization_file/app_localizations.dart';

/// Shown when no registered source can satisfy a route.
class const NoMediaSourceScreen({
  super.key,
  final String message = 'No media source available',
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.sourceUnavailable ??
              'Source unavailable',
        ),
      ),
      body: Center(child: Text(message)),
    );
  }
}
