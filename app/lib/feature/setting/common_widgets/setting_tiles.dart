import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app_scaffold.dart' show $styles;
import '../../../design/design.dart';

/// Section label that groups related setting rows.
class const SettingSectionHeader({super.key, required final String title})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: $styles.insets.md,
      top: $styles.insets.sm,
      bottom: $styles.insets.xs,
    ),
    child: Text(
      title,
      style: $styles.text.bodySmall.copyWith(
        color: $styles.colors.onSurfaceVariant,
      ),
    ),
  );
}

/// Boolean setting row rendered as a switch.
class const SettingSwitchTile({
  super.key,
  required final String title,
  final String? subtitle,
  required final bool value,
  required final ValueChanged<bool> onChanged,
  final String? tooltip,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final subtitleText = subtitle;
    final tile = SwitchListTile(
      title: Text(title),
      subtitle: subtitleText == null ? null : Text(subtitleText),
      value: value,
      onChanged: (next) {
        HapticFeedback.selectionClick();
        onChanged(next);
      },
    );
    final message = tooltip;
    return message == null ? tile : Tooltip(message: message, child: tile);
  }
}

/// Setting row that shows the current value and opens a picker when tapped.
class const SettingValueTile({
  super.key,
  required final String title,
  required final String subtitle,
  required final String value,
  required final VoidCallback onTap,
  final String? tooltip,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip ?? '$title: $value',
    child: ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: $styles.text.bodySmall.copyWith(
              color: $styles.colors.onSurfaceVariant,
            ),
          ),
          Icon(AppIcons.chevronRight, color: $styles.colors.onSurfaceVariant),
        ],
      ),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
    ),
  );
}

/// Header for a modal bottom-sheet picker.
class const SettingPickerTitle({super.key, required final String title})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: $styles.insets.sm),
    child: Text(title, style: $styles.text.bodySmallBold),
  );
}

/// Single-choice option inside a modal bottom-sheet picker.
class const SettingPickerOption({
  super.key,
  required final String title,
  required final bool selected,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(title),
    selected: selected,
    trailing: selected
        ? Icon(AppIcons.check, color: $styles.colors.accentText)
        : null,
    onTap: () {
      HapticFeedback.selectionClick();
      onTap();
    },
  );
}

/// Setting row that performs an action, optionally with a trailing chevron.
class const SettingActionTile({
  super.key,
  required final IconData icon,
  required final String title,
  final String? subtitle,
  final bool showChevron = false,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final subtitleText = subtitle;
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitleText == null ? null : Text(subtitleText),
      trailing: showChevron ? const Icon(AppIcons.chevronRight) : null,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
    );
  }
}
