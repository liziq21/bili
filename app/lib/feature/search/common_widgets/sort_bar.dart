import 'package:data/data.dart';
import 'package:material_ui/material_ui.dart';
import 'package:youtube/youtube.dart';

class const SortBar({
  super.key,
  required final List<SortOption> sortOptions,
  final SortOption? current,
  final void Function(SortOption?)? onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (sortOptions.isEmpty) return const SizedBox.shrink();
    return DropdownButton<SortOption>(
      value: current ?? sortOptions.first,
      onChanged: onChanged,
      items: sortOptions.map((option) {
        return DropdownMenuItem<SortOption>(
          value: option,
          child: Text(option.localizedLabel(context)),
        );
      }).toList(),
    );
  }
}
