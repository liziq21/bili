import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../main.dart';
import '../bloc/home_bloc.dart';

/// 主页 AppBar 中的「数据源切换」下拉按钮
class const HomeSourceSelector({
  super.key,
  required final List<MediaSource> sources,
  required final String activeSourceId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: activeSourceId,
        isDense: true,
        icon: Icon(Icons.arrow_drop_down, color: colorScheme.onSurfaceVariant),
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
          context.read<HomeBloc>().add(ServiceSourceChanged(newSource));
        },
      ),
    );
  }
}
