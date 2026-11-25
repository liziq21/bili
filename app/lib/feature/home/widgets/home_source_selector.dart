import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../design/design.dart';
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

    return Tooltip(
      message: l10n?.switchDataSource ?? 'Switch source',
      // 不排除子语义：`DropdownButton` 自己的选中值与 tap 动作必须保留，否则
      // 读屏用户听得到当前来源却打不开菜单。这里只补 label/hint 作上下文。
      child: Semantics(
        label: semanticLabel,
        hint: l10n?.switchVideoMediaSource ?? 'Switch video and media source',
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: activeSourceId,
            isDense: true,
            icon: Icon(AppIcons.dropDown, color: colorScheme.onSurfaceVariant),
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
