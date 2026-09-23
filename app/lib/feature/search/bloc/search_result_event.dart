part of 'search_result_bloc.dart';

sealed class const SearchResultEvent() extends Equatable {
  @override
  List<Object?> get props => [];
}

final class const FetchNextPage() extends SearchResultEvent;
