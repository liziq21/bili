part of 'search_result_bloc.dart';

sealed class SearchResultEvent extends Equatable {
  const SearchResultEvent();

  @override
  List<Object?> get props => [];
}

final class const FetchNextPage() extends SearchResultEvent;
