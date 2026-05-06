import 'package:flutter/material.dart';
import '../../../model/data/filter_group.dart';

class FilterGroupWidget extends StatelessWidget {
  const FilterGroupWidget({
    super.key,
    required this.group,
    required this.onChanged,
  });

  final FilterGroup group;
  final ValueChanged<FilterGroup> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Text(
            group.label,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: .bold),
          ),
        ),
        switch (group) {
          SingleFilterGroup g => _SingleFilterView(
            group: g,
            onChanged: onChanged,
          ),
          MultiFilterGroup g => _MultiFilterView(
            group: g,
            onChanged: onChanged,
          ),
          DateRangeFilterGroup g => _DateRangeView(
            group: g,
            onChanged: onChanged,
          ),
        },
        const Divider(height: 1),
      ],
    );
  }
}

class _SingleFilterView extends StatelessWidget {
  const _SingleFilterView({required this.group, required this.onChanged});

  final SingleFilterGroup group;
  final ValueChanged<FilterGroup> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Wrap(
        spacing: 8.0,
        children: group.options.map((option) {
          final isSelected = group.selection == option;
          return FilterChipItem(
            key: option.value,
            label: option.label,
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                onChanged(group.copyWith(selection: option));
              }
            },
          );
        }).toList(),
      ),
    );
  }
}

class _MultiFilterView extends StatelessWidget {
  const _MultiFilterView({required this.group, required this.onChanged});

  final MultiFilterGroup group;
  final ValueChanged<FilterGroup> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Wrap(
        spacing: 8.0,
        children: group.options.map((option) {
          final isSelected = group.isSelected(option);
          return FilterChipItem(
            key: option.id,
            label: option.label,
            selected: isSelected,
            onSelected: (selected) {
              final newSet = Set<FilterOption>.from(group.selectedOptions);
              if (selected) {
                newSet.add(option);
              } else {
                newSet.remove(option);
              }
              onChanged(group.copyWith(selectedOptions: newSet));
            },
          );
        }).toList(),
      ),
    );
  }
}

class _DateRangeView extends StatelessWidget {
  const _DateRangeView({required this.group, required this.onChanged});

  final DateRangeFilter group;
  final ValueChanged<FilterGroup> onChanged;

  @override
  Widget build(BuildContext context) {
    final range = group.customDateRange;
    final label = range == null
        ? "选择日期范围"
        : "${range.start.year}-${range.end.year}";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: OutlinedButton.icon(
        icon: const Icon(Icons.calendar_month, size: 18),
        label: Text(label),
        onPressed: () async {
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
          );
          if (picked != null) {
            onChanged(
              group.copyWith(
                customDateRange: (start: picked.start, end: picked.end),
              ),
            );
          }
        },
      ),
    );
  }
}
