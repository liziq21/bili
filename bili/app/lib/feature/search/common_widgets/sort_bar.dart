import 'package:data/data.dart';
import 'package:flutter/material.dart';

class SortBar extends StatelessWidget {
  const SortBar({super.key, required this.sortOptions, this.onChanged});

  final List<SortOption> sortOptions;
  final void Function(SortOption?)? onChanged;

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

