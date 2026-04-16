import 'package:flutter/material.dart';
import '../../../model/data/sort_option.dart';

class SortBar extends StatelessWidget {
  const SortBar({
    super.key,
    required this.vm,
  });
  
  final vm;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<SortOption>(
      value: vm.currentSort,
      onChanged: (newValue) {
        if (newValue != null && newValue != vm.currentSort) {
          vm.onSortChanged(newValue);
        }
      },
      items: vm.SortOptions.map((option) {
        return DropdownMenuItem<SortOption>(
          value: option,
          child: Text(option.label),
        );
      }).toList(),
    );
  }
}