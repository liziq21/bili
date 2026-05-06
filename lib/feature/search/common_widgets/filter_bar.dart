import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../model/data/filter_group.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    required this.filters,
    required this.onChanged,
  });
  
  final List<FilterGroup> filters;
  final Function (List<FilterGroup>) onChanged; 

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _showFilterBottomSheet(context), 
      icon: const Icon(Icons.filter),
    );
  }
  
  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: .min,
          children: [
            AppBar(
              title: Text('筛选器'),
              automaticallyImplyLeading: false,
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: .min,
                  children: ListView.builder(
                    itemCount: vm.filters.length,
                    itemBuilder: (_, index) {
                      return Selector<SearchViewModel, FilterGroup>(
                        selector: (_, vm) => vm.filters[index],
                        builder: (context, group, child) {
                          return FilterGroupWidget(
                            key: group.label,
                            group: group,
                            onChanged: vm.onFilterChanged,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    );
  }
}
