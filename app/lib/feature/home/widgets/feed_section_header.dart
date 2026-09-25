import 'package:material_ui/material_ui.dart';

import '../../../main.dart';

/// Feed 区块标题
class const FeedSectionHeader({
  super.key,
  required final String title,
  required final String subtitle,
  required final IconData icon,
  final Color? iconColor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        $styles.insets.sm,
        $styles.insets.sm,
        $styles.insets.sm,
        $styles.insets.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: $styles.insets.xxs),
            child: Icon(icon, color: iconColor ?? colorScheme.primary),
          ),
          SizedBox(width: $styles.insets.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: $styles.text.h3.copyWith(color: colorScheme.onSurface),
                ),
                Text(
                  subtitle,
                  style: $styles.text.bodySmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
