import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../design/design.dart';
import '../l10n/localization_file/app_localizations.dart';
import '../main.dart';

/// Presentational subscribe/unsubscribe toggle for a creator.
///
/// State lives with the caller: this widget only renders [isSubscribed] and
/// forwards taps through [onPressed].
class const CreatorSubscribeButton({
  super.key,
  required final bool isSubscribed,
  required final VoidCallback onPressed,
  final bool compact = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = isSubscribed
        ? (l10n?.unsubscribe ?? 'Unsubscribe')
        : (l10n?.subscribe ?? 'Subscribe');

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        selected: isSubscribed,
        excludeSemantics: true,
        label: label,
        tooltip: label,
        onTap: onPressed,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: isSubscribed
                ? $styles.colors.outline.withValues(alpha: 0.3)
                : $styles.colors.accentFill,
            foregroundColor: isSubscribed
                ? $styles.colors.onSurface
                : $styles.colors.onAccentFill,
            elevation: 0,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? $styles.insets.xs : $styles.insets.sm,
              vertical: $styles.insets.xxs,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular($styles.corners.lg),
            ),
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            onPressed();
          },
          icon: Icon(
            isSubscribed ? AppIcons.check : AppIcons.personAdd,
            size: compact ? 16 : 18,
          ),
          label: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: $styles.text.btn.copyWith(fontSize: compact ? 12 : 13),
          ),
        ),
      ),
    );
  }
}
