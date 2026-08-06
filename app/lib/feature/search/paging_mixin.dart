import 'package:data/data.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:model/model.dart';

mixin PagingMixin<T> {
  PagingState<int, T> _state = .new();

  PagingState<int, T> get state => _state;

  Future<Result<Page<T>>> fetchPage(int pageKey);

  void fetchNextPage() async {
    if (_state.isLoading) return;
    final newKey = (_state.keys?.last ?? 0) + 1;
    final result = await fetchPage(newKey);
    _state = switch (result) {
      Ok(:final value) => _state.copyWith(
        pages: [...?_state.pages, value.data],
        keys: [...?_state.keys, newKey],
        hasNextPage: newKey < value.totalPages,
        isLoading: false,
      ),
      Error(:final error) => _state.copyWith(error: error, isLoading: false),
    };
  }

  void refresh() {
    _state = _state.reset();
  }
}
