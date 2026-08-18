import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import 'bloc/search_result_bloc.dart';

class const SearchResult<T>({
  super.key,
  required final ItemWidgetBuilder<T> itemBuilder,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          BlocSelector<
            SearchResultBloc<T>,
            SearchResultState<T>,
            PagingState<int, T>
          >(
            selector: ((state) => state.pagingState),
            builder: (context, state) {
              return PagedSliverList<int, T>(
                state: state,
                fetchNextPage: () =>
                    context.read<SearchResultBloc<T>>().add(FetchNextPage()),
                builderDelegate: PagedChildBuilderDelegate(
                  itemBuilder: itemBuilder,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
