import 'package:data/data.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../main.dart';
import '../bloc/home_bloc.dart';

/// 主页 AppBar 中的「数据源切换 + 搜索」输入条
class const HomeSearchBar({
    super.key,
    required final TextEditingController controller,
    required final List<MediaSource> sources,
    required final String activeSourceId,
    required final String activeSourceName,
    required final ValueChanged<String> onSubmitted,
  }) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular($styles.corners.lg),
      ),
      child: Row(
        children: [
          Flexible(
            child: Padding(
              padding: EdgeInsets.only(left: $styles.insets.xs),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: activeSourceId,
                  isDense: true,
                  isExpanded: true,
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
                    context.read<HomeBloc>().add(
                      ServiceSourceChanged(newSource),
                    );
                  },
                ),
              ),
            ),
          ),
          VerticalDivider(
            indent: $styles.insets.xs,
            endIndent: $styles.insets.xs,
            width: $styles.insets.sm,
            color: colorScheme.outlineVariant,
          ),
          Expanded(
            flex: 2,
            child: TextField(
              controller: controller,
              maxLength: 200,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              textAlignVertical: TextAlignVertical.center,
              style: $styles.text.bodySmall.copyWith(
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: '搜索 $activeSourceName 内容...',
                hintStyle: $styles.text.bodySmall.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                ),
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: $styles.insets.xs,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.search_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  tooltip: '搜索',
                  onPressed: () => onSubmitted(controller.text),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
