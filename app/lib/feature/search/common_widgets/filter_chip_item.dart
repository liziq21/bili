import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// How a [FilterChipItem] caller interprets the `false` that `ChoiceChip`
/// reports when the already-selected chip is tapped again.
///
/// `ChoiceChip` is single-select in its own right: tapping the selected chip
/// reports `false` because there is nothing left to select. Whether that `false`
/// is a state change therefore depends entirely on the caller.
enum FilterChipSelectionMode() {
  /// The caller keeps its selection when it receives `false`, so re-tapping the
  /// selected chip changes nothing.
  single,

  /// The caller removes the option when it receives `false`, so re-tapping the
  /// selected chip is a deselection.
  multiple,
}

class const FilterChipItem({
  super.key,
  required final String label,
  required final bool isSelected,
  required final FilterChipSelectionMode selectionMode,
  required final ValueChanged<bool> onSelected,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      tooltip: label,
      onSelected: (selected) {
        // Under [FilterChipSelectionMode.single] the `false` arrives when the
        // already-selected chip is tapped again and the caller keeps its
        // selection, so nothing changed and a confirmation haptic would be a
        // lie. Under [FilterChipSelectionMode.multiple] the same `false` is a
        // deselection, a real change that deserves the same feedback as a
        // selection.
        final isStateChange = switch (selectionMode) {
          FilterChipSelectionMode.single => selected,
          FilterChipSelectionMode.multiple => true,
        };
        if (isStateChange) HapticFeedback.selectionClick();
        onSelected(selected);
      },
    );
  }
}
