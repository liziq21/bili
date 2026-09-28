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
      onSelected: onSelected,
    );
  }
}
