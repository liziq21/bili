import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import 'bloc/search_result_bloc.dart';

class SearchResult<T> extends StatelessWidget {
  const SearchResult({
    super.key,
    required this.itemBuilder,
    this.itemAspectRatio = 1.0,
    this.maxCrossAxisExtent = 200.0,
  });

  final ItemWidgetBuilder<T> itemBuilder;
  final double itemAspectRatio;
  final double maxCrossAxisExtent;

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
                  context.read<SearchResultBloc<T>>().add(const FetchNextPage()),
              builderDelegate: PagedChildBuilderDelegate(
                itemBuilder: itemBuilder,
                firstPageErrorIndicatorBuilder: (context) {
                  final error = state.error;
                  debugPrint('👉 第一页加载失败原因: $error');
                  return Center(child: Text('加载失败: $error'));
                },
                newPageErrorIndicatorBuilder: (context) {
                  final error = state.error;
                  debugPrint('👉 后续页加载失败原因: $error');
                  return Center(child: Text('更多数据加载失败: $error'));
                },
              ),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: maxCrossAxisExtent,
                mainAxisSpacing: 10.0,
                crossAxisSpacing: 10.0,
                childAspectRatio: itemAspectRatio,
              ),
            ),
          ],
        );
      },
    );
  }
}
