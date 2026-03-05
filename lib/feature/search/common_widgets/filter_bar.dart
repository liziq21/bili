import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../model/data/filter_group.dart';

class FilterBar extends StatelessWidget {
  final List<FilterGroup> initialFilters;
  final List<FilterGroup> activeFilters;
  final ValueChanged<List<FilterGroup>> onFiltersChanged;

  const FilterBar({
    super.key,
    required this.initialFilters,
    this.activeFilters = const [],
    required this.onFiltersChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (activeFilters.isEmpty) return const SizedBox.shrink();

    return ElevatedButton.icon(
      onPressed: () => _showFilterBottomSheet(context),
      icon: const Icon(Icons.filter_list),
      label: Text('筛选 (${_getSelectedFilterCount(activeFilters)})'),
    );
  }

  int _getSelectedFilterCount(List<FilterGroup> filters) {
    return filters.where((group) => group.selectedOptions.isNotEmpty || (group is DateRangeFilter && group.hasCustomRange)).length;
  }

  void _showFilterBottomSheet(BuildContext context) {
    List<FilterGroup> tempFilters = activeFilters.map((f) => f.copyWith()).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppBar(
                    title: const Text('筛选器'),
                    automaticallyImplyLeading: false,
                    actions: [
                      TextButton(onPressed: () => modalSetState(() => tempFilters = initialFilters.map((f) => f.toDefault()).toList()), child: const Text('重置')),
                      TextButton(onPressed: () {Navigator.pop(context); onFiltersChanged(tempFilters);}, child: const Text('应用')),
                    ],
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...tempFilters.map((group) {
                            if (group is DateRangeFilter) return _buildDateRangeFilter(group, modalSetState, tempFilters);
                            if (group is CategoryFilter) return _buildCategoryFilter(group, modalSetState, tempFilters);
                            return const SizedBox.shrink();
                          }).toList(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _updateTempFilterGroup(List<FilterGroup> tempFilters, FilterGroup originalGroup, FilterGroup updatedGroup, StateSetter modalSetState) {
    modalSetState(() {
      final index = tempFilters.indexOf(originalGroup);
      if (index != -1) tempFilters[index] = updatedGroup;
    });
  }

  Widget _buildCategoryFilter(CategoryFilter group, StateSetter modalSetState, List<FilterGroup> tempFilters) {
    return ExpansionTile(
      title: Text(group.label),
      children: group.options.map((option) {
        return CheckboxListTile(
          title: Text(option.label),
          value: group.selectedOptions.contains(option),
          onChanged: (bool? isChecked) {
            List<FilterOption> newSelectedOptions = List.from(group.selectedOptions);
            isChecked == true ? newSelectedOptions.add(option) : newSelectedOptions.remove(option);
            _updateTempFilterGroup(tempFilters, group, group.withSelectedOptions(newSelectedOptions) as CategoryFilter, modalSetState);
          },
        );
      }).toList(),
    );
  }

  Widget _buildDateRangeFilter(DateRangeFilter group, StateSetter modalSetState, List<FilterGroup> tempFilters) {
    return ExpansionTile(
      title: Text(group.label),
      children: [
        ...group.options.map((option) {
          return RadioListTile<FilterOption>(
            title: Text(option.label),
            value: option,
            groupValue: group.hasCustomRange ? null : (group.selectedOptions.isNotEmpty ? group.selectedOptions.first : null),
            onChanged: (FilterOption? newValue) {
              if (newValue != null) {
                _updateTempFilterGroup(
                    tempFilters, group,
                    group.copyWith(selectedOptions: [newValue], clearCustomDateRange: true) as DateRangeFilter,
                    modalSetState);
              }
            },
          );
        }).toList(),
        ListTile(
          title: const Text('自定义日期范围'),
          trailing: Text(group.hasCustomRange
              ? '\({group.customDateRange!.start.toString().split(' ').first} - \){group.customDateRange!.end.toString().split(' ').first}'
              : '选择'),
          onTap: () async {
            final DateTimeRange? picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2000),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              initialDateRange: group.hasCustomRange ? DateTimeRange(start: group.customDateRange!.start, end: group.customDateRange!.end) : null,
            );
            if (picked != null) {
              _updateTempFilterGroup(
                  tempFilters, group,
                  group.copyWith(customDateRange: (start: picked.start, end: picked.end), selectedOptions: []) as DateRangeFilter,
                  modalSetState);
            }
          },
        ),
      ],
    );
  }
}