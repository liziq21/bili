import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../model/data/filter_group.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    required this.viewModel,
  });
  
  final List<FilterGroup> viewModel;

  @override
  Widget build(BuildContext context) {
    return ;
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
            const AppBar(
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
