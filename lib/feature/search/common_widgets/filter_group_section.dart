import 'package:flutter/material.dart';
import 'filter_chip_item.dart';
import '../../../model/data/filter_group.dart';

class FilterGroupSection extends StatelessWidget {
  const FilterGroupSection({
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
          final SingleFilterGroup g => _SingleFilterView(
            group: g,
            onChanged: onChanged,
          ),
          final MultiFilterGroup g => _MultiFilterView(
            filter: g,
            onChanged: onChanged,
          ),
          final DateRangeFilterGroup g => _DateRangeView(
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
            key: ValueKey(option.value),
            label: option.label,
            isSelected: isSelected,
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
  const _MultiFilterView({required this.filter, required this.onChanged});

  final MultiFilterGroup filter;
  final ValueChanged<FilterGroup> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Wrap(
        spacing: 8.0,
        children: filter.options.map((option) {
          final isSelected = filter.isSelected(option);
          return FilterChipItem(
            key: ValueKey(option.value),
            label: option.label,
            isSelected: isSelected,
            onSelected: (selected) {
              final newSet = Set<FilterOption>.from(filter.selections);
              if (selected) {
                newSet.add(option);
              } else {
                newSet.remove(option);
              }
              onChanged(filter.copyWith(selections: newSet));
            },
          );
        }).toList(),
      ),
    );
  }
}

class _DateRangeView extends StatelessWidget {
  const _DateRangeView({required this.group, required this.onChanged});

  final DateRangeFilterGroup group;
  final ValueChanged<FilterGroup> onChanged;

  @override
  Widget build(BuildContext context) {
    final range = group.range;
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
              group.copyWith(range: (start: picked.start, end: picked.end)),
            );
          }
        },
      ),
    );
  }
}
