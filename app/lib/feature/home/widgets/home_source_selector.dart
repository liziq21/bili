import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/localization_file/app_localizations.dart';
import '../../../main.dart';
import '../../../providers/media_sources_provider.dart';
import '../bloc/home_bloc.dart';

/// 主页 AppBar 中的「数据源切换」下拉按钮
class const HomeSourceSelector({
  super.key,
  required final List<MediaSourceDefinition> sources,
  required final String activeSourceId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    final semanticLabel = l10n?.switchDataSource ?? 'Switch source';
    MediaSourceDefinition activeSource;
    try {
      activeSource = sources.firstWhere((s) => s.id == activeSourceId);
    } on StateError {
      activeSource = sources.first;
    }
    final activeSourceName = activeSource.name;

    return Tooltip(
      message: l10n?.switchDataSource ?? 'Switch source',
      child: Semantics(
        button: true,
        label: semanticLabel,
        value: activeSourceName,
        hint: l10n?.switchVideoMediaSource ?? 'Switch video and media source',
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: activeSourceId,
            isDense: true,
            icon: Icon(
              Icons.arrow_drop_down,
              color: colorScheme.onSurfaceVariant,
            ),
            items: [
              for (final source in sources)
                DropdownMenuItem<String>(
                  value: source.id,
                  child: Text(
                    source.name,
                    overflow: TextOverflow.ellipsis,
                    style: $styles.text.title2.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
            ],
            onChanged: (newSource) {
              if (newSource == null) return;
              if (newSource != activeSourceId) {
                HapticFeedback.selectionClick();
              }
              context.read<HomeBloc>().add(ServiceSourceChanged(newSource));
            },
          ),
        ),
      ),
    );
  }
}
