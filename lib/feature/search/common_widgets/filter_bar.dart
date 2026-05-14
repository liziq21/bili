import 'package:flutter/material.dart';
import 'filter_group_section.dart';
import '../../../model/data/filter_group.dart';

typedef FilterChangedCallback = void Function(List<FilterGroup> updatedFilters);

class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    required this.filters,
    required this.onChanged,
    this.title = '筛选器',
  });

  final List<FilterGroup> filters;
  final FilterChangedCallback onChanged;
  final String title;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _showFilterBottomSheet(context),
      icon: const Icon(Icons.filter_list),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    // 深拷贝一份数据，避免直接修改外部原始数据
    // 如果没有点击确定，外部数据不应改变
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        // 使用 StatefulBuilder 让 BottomSheet 内部支持状态刷新
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              expand: false,
              builder: (_, scrollController) {
                return Column(
                  children: [
                    _buildHeader(context),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filters.length,
                        itemBuilder: (context, index) {
                          return FilterGroupSection(
                            group: filters[index],
                            onChanged: (f) => setModalState(() {
                              filters[index] = f;
                            }), // 刷新面板
                          );
                        },
                      ),
                    ),
                    _buildFooter(context),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  // 实现重置逻辑
                  Navigator.pop(context);
                },
                child: const Text('重置'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  onChanged(filters);
                  Navigator.pop(context);
                },
                child: const Text('确定'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
