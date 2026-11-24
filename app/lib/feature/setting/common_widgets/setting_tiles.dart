import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app_scaffold.dart' show $styles;
import '../../../design/design.dart';

/// Section label that groups related setting rows.
///
/// Only add one when it names the **group** and holds several rows. A header
/// that repeats the label of its single row is noise; the left inset matches
/// `ListTile`'s default `contentPadding` so the two left edges line up.
class const SettingSectionHeader({super.key, required final String title})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      // Fixed rather than `$styles.insets.sm`: ListTile's content padding does
      // not scale with the layout breakpoint, so a scaled inset would drift off
      // the row text on tablets.
      left: 16,
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

/// One choice of a [SettingMultiSelectTile].
@immutable
class const SettingMultiSelectOption<T>(final T value, final String label);

/// Setting row that edits free text. Tapping opens a dialog pre-filled with
/// [value]; confirming reports the trimmed input.
class const SettingTextTile({
  super.key,
  required final String title,
  final String? subtitle,
  required final String value,
  required final ValueChanged<String> onChanged,
  final String? hintText,
  final int? maxLength,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final subtitleText = subtitle;
    return ListTile(
      title: Text(title),
      subtitle: subtitleText == null ? null : Text(subtitleText),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: $styles.text.bodySmall.copyWith(
                color: $styles.colors.onSurfaceVariant,
              ),
            ),
          ),
          Icon(AppIcons.chevronRight, color: $styles.colors.onSurfaceVariant),
        ],
      ),
      onTap: () => _edit(context),
    );
  }

  Future<void> _edit(BuildContext context) async {
    unawaited(HapticFeedback.selectionClick());
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _TextInputDialog(
        title: title,
        initialValue: value,
        hintText: hintText,
        maxLength: maxLength,
      ),
    );
    if (result == null || !context.mounted) return;
    onChanged(result.trim());
  }
}

/// 自由文本编辑对话框。自己持有 [TextEditingController]，随对话框一起销毁，
/// 避免调用方在退场动画还在用 controller 时提前 dispose。
class const _TextInputDialog({
  required final String title,
  required final String initialValue,
  final String? hintText,
  final int? maxLength,
}) extends StatefulWidget {
  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState() extends State<_TextInputDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = MaterialLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: widget.maxLength,
        textInputAction: TextInputAction.done,
        onSubmitted: (text) => Navigator.of(context).pop(text),
        decoration: InputDecoration(hintText: widget.hintText),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButtonLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(l10n.okButtonLabel),
        ),
      ],
    );
  }
}

/// Setting row that edits a set of choices. The selected labels are shown
/// inline; tapping opens a checkbox sheet and reports the new selection.
class const SettingMultiSelectTile<T extends Object>({
  super.key,
  required final String title,
  final String? subtitle,
  required final List<SettingMultiSelectOption<T>> options,
  required final Set<T> selected,
  required final ValueChanged<Set<T>> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final subtitleText = subtitle;
    final selectedLabels = [
      for (final option in options)
        if (selected.contains(option.value)) option.label,
    ];
    return ListTile(
      title: Text(title),
      subtitle: subtitleText == null ? null : Text(subtitleText),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selectedLabels.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                selectedLabels.join(', '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: $styles.text.bodySmall.copyWith(
                  color: $styles.colors.onSurfaceVariant,
                ),
              ),
            ),
          Icon(AppIcons.chevronRight, color: $styles.colors.onSurfaceVariant),
        ],
      ),
      onTap: () => _pick(context),
    );
  }

  Future<void> _pick(BuildContext context) async {
    unawaited(HapticFeedback.selectionClick());
    final okLabel = MaterialLocalizations.of(context).okButtonLabel;
    final result = await showModalBottomSheet<Set<T>>(
      context: context,
      builder: (sheetContext) {
        // 只保留仍出现在 options 里的已选值：弹层无法渲染或清除未知值，
        // 因此把它们从工作集里剔除以避免回传用户看不见的残留项。
        final optionValues = {for (final option in options) option.value};
        final working = <T>{...selected.where(optionValues.contains)};
        return StatefulBuilder(
          builder: (_, setState) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: [
                SettingPickerTitle(title: title),
                for (final option in options)
                  CheckboxListTile(
                    value: working.contains(option.value),
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(option.label),
                    onChanged: (checked) => setState(() {
                      if (checked == true) {
                        working.add(option.value);
                      } else {
                        working.remove(option.value);
                      }
                    }),
                  ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: $styles.insets.sm),
                  child: Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(sheetContext).pop(working),
                      child: Text(okLabel),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (result == null || !context.mounted) return;
    onChanged(result);
  }
}
