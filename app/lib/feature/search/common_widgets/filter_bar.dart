import 'package:data/data.dart';
import 'package:material_ui/material_ui.dart';

import '../../../design/design.dart';
import '../../../l10n/localization_file/app_localizations.dart';
import '../../../main.dart';
import 'filter_group_section.dart';

typedef FilterChangedCallback = void Function(List<FilterGroup> updatedFilters);

class const FilterBar({
  super.key,
  required final List<FilterGroup> filters,
  required final FilterChangedCallback onChanged,
  final List<FilterGroup>? defaults,
  final String? title,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final effectiveTitle = title ?? l10n?.filters ?? 'Filters';

    return IconButton(
      tooltip: effectiveTitle,
      onPressed: () => _showFilterBottomSheet(context, effectiveTitle),
      icon: const Icon(AppIcons.filter),
    );
  }

  void _showFilterBottomSheet(BuildContext context, String effectiveTitle) {
    // 深拷贝一份数据，避免直接修改 bloc state 里的列表。
    final working = List<FilterGroup>.of(filters);
    final resetValues = defaults ?? filters;

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
                        itemCount: working.length,
                        itemBuilder: (context, index) {
                          return FilterGroupSection(
                            group: working[index],
                            onChanged: (f) => setModalState(() {
                              working[index] = f;
                            }), // 刷新面板
                          );
                        },
                      ),
                    ),
                    _buildFooter(context, working, resetValues),
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

  Widget _buildFooter(
    BuildContext context,
    List<FilterGroup> working,
    List<FilterGroup> resetValues,
  ) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  onChanged(List.unmodifiable(resetValues));
                  Navigator.pop(context);
                },
                child: Text(l10n?.reset ?? 'Reset'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  onChanged(List.unmodifiable(working));
                  Navigator.pop(context);
                },
                child: Text(l10n?.confirm ?? 'Confirm'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
