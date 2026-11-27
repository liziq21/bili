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
            // 高度随条件组数量收缩，只在条件多到放不下时才封顶滚动。固定
            // 占比会让只有一组条件时（例如视频结果只有「视频时长」）条件区
            // 下方留出几百像素空白。上限写在这里而不是传给
            // showModalBottomSheet：传了 constraints 会顶掉它默认的 640dp
            // 宽度上限，宽窗口下面板会铺满屏幕。
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.9,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(context, effectiveTitle),
                  Flexible(
                    child: _PullDownToDismiss(
                      child: ListView.builder(
                        shrinkWrap: true,
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
                  ),
                  _buildFooter(context, working, resetValues),
                ],
              ),
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

/// 列表滚到顶部后继续下拉时关闭面板。
///
/// 列表一旦可以滚动就会独占纵向拖动手势，外层面板的拖拽关闭收不到同一个
/// 手势；这里把越过列表顶部的下拉距离累计起来，在手势结束时关闭面板。
class const _PullDownToDismiss({required final Widget child})
    extends StatefulWidget {
  @override
  State<_PullDownToDismiss> createState() => _PullDownToDismissState();
}

class _PullDownToDismissState() extends State<_PullDownToDismiss> {
  static const _threshold = 80.0;

  double _distance = 0;

  bool _onNotification(ScrollNotification notification) {
    switch (notification) {
      case OverscrollNotification(:final overscroll) when overscroll < 0:
        _distance -= overscroll;
      case ScrollUpdateNotification():
        _distance = 0;
      case ScrollEndNotification():
        final shouldClose = _distance >= _threshold;
        _distance = 0;
        if (shouldClose) Navigator.of(context).maybePop();
      default:
        break;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        onNotification: _onNotification,
        child: widget.child,
      );
}
