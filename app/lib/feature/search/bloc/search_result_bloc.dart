import 'package:bloc/bloc.dart';
import 'package:data/data.dart';
// ignore: depend_on_referenced_packages
import 'package:equatable/equatable.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:model/model.dart';

import '../../../data/repository/search_contents_repository.dart';

part 'search_result_event.dart';
part 'search_result_state.dart';

class SearchResultBloc<T>({
  required final SearchContentsRepository<T> searchContentsRepository,
}) extends Bloc<SearchResultEvent, SearchResultState<T>> {
  this : super(SearchResultState(pagingState: .new())) {
    on<FetchNextPage>(_fetchNextPage);
  }

  Future<void> _fetchNextPage(
    FetchNextPage event,
    Emitter<SearchResultState> emit,
  ) async {
    if (state.pagingState.isLoading) return;

    emit(
      state.updatePagingStete(
        (pagingState) => pagingState.copyWith(isLoading: true),
      ),
    );

    final searchQuery = state.searchQuery;
    final result = await searchContentsRepository.search(searchQuery);

    emit(
      state.updatePagingStete(
        (pagingState) => switch (result) {
          Ok(:final value) => pagingState.copyWith(
            pages: [...?pagingState.pages, value.data],
            keys: [...?pagingState.keys, searchQuery.pageKey],
            hasNextPage: searchQuery.pageKey < value.totalPages,
            isLoading: false,
          ),
          Error(:final error) => pagingState.copyWith(
            error: error,
            isLoading: false,
          ),
        },
      ),
    );
  }
}
