import 'package:data/data.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/localization_file/app_localizations.dart';
import '../../../main.dart';
import 'filter_group_section.dart';

typedef FilterChangedCallback = void Function(List<FilterGroup> updatedFilters);

class const FilterBar({
  super.key,
  required final List<FilterGroup> filters,
  required final FilterChangedCallback onChanged,
  final String? title,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final effectiveTitle = title ?? l10n.filters;

    return IconButton(
      tooltip: effectiveTitle,
      onPressed: () => _showFilterBottomSheet(context, effectiveTitle),
      icon: const Icon(Icons.filter_list),
    );
  }

  void _showFilterBottomSheet(BuildContext context, String effectiveTitle) {
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
                    _buildHeader(context, effectiveTitle),
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

  Widget _buildHeader(BuildContext context, String effectiveTitle) {
    return Column(
      children: [
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: $styles.colors.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            effectiveTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                child: Text(l10n.reset),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  onChanged(filters);
                  Navigator.pop(context);
                },
                child: Text(l10n.confirm),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
