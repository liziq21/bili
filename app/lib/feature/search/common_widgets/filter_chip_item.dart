import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

class const FilterChipItem({
  super.key,
  required final String label,
  required final bool isSelected,
  required final ValueChanged<bool> onSelected,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      tooltip: label,
      onSelected: (selected) {
        // `ChoiceChip` reports `false` when the already-selected chip is tapped
        // again. Single-select callers (filter_group_section.dart:61) ignore
        // that value and keep the selection, so the tap changes nothing and
        // must not produce a confirmation haptic. Multi-select callers do treat
        // `false` as a deselection, which is a real state change.
        if (selected || !isSelected) HapticFeedback.selectionClick();
        onSelected(selected);
      },
    );
  }
}
