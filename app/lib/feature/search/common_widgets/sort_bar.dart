import 'package:data/data.dart';
import 'package:material_ui/material_ui.dart';

class const SortBar({super.key, required final List<SortOption> sortOptions, final void Function(SortOption?)? onChanged}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DropdownButton<SortOption>(
      value: sortOptions.first,
      onChanged: onChanged,
      items: sortOptions.map((option) {
        return DropdownMenuItem<SortOption>(
          value: option,
          child: Text(option.label),
        );
      }).toList(),
    );
  }
}
