import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import 'bloc/search_result_bloc.dart';

class const SearchResult<T>({
  super.key,
  required final ItemWidgetBuilder<T> itemBuilder,

  final double itemAspectRatio = 1.0,
  final double maxCrossAxisExtent = 200.0,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      SearchResultBloc<T>,
      SearchResultState<T>,
      PagingState<int, T>
    >(
      selector: (state) => state.pagingState,
      builder: (context, state) {
        return CustomScrollView(
          slivers: [
            PagedSliverGrid<int, T>(
              state: state,
              fetchNextPage: () =>
                  context.read<SearchResultBloc<T>>().add(FetchNextPage()),
              builderDelegate: PagedChildBuilderDelegate(
                itemBuilder: itemBuilder,
                firstPageErrorIndicatorBuilder: (context) {
                  return const Center(child: Text('加载失败，请稍后重试'));
                },
                newPageErrorIndicatorBuilder: (context) {
                  return const Center(child: Text('更多数据加载失败，请稍后重试'));
                },
                noItemsFoundIndicatorBuilder: (context) {
                  final colorScheme = Theme.of(context).colorScheme;
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '未找到内容',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: maxCrossAxisExtent,
                mainAxisSpacing: 10.0,
                crossAxisSpacing: 10.0,
                // 💡 放弃固定 mainAxisExtent，改用自适应比例
                childAspectRatio: itemAspectRatio,
              ),
            ),
          ],
        );
      },
    );
  }
}
