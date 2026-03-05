// views/common_widgets/sort_bar.dart
import 'package:flutter/material.dart';
import '../../../model/data/sort_option.dart';

class SortBar<S extends SortOption> extends StatelessWidget {
  final List<S> availableSortOptions;
  final S? currentSortBy;
  final ValueChanged<S> onSortChanged;

  const SortBar({
    super.key,
    this.availableSortOptions = const [],
    this.currentSortBy,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (availableSortOptions.isEmpty) return const SizedBox.shrink();

    return DropdownButton<S>(
      value: currentSortBy,
      hint: const Text('排序'),
      onChanged: (newValue) => newValue != null ? onSortChanged(newValue) : null,
      items: availableSortOptions.map((option) =>
          DropdownMenuItem<S>(value: option, child: Text(option.label))).toList(),
    );
  }
}