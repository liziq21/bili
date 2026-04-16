import '../../utils/result.dart'

typedef PagedResult<T> = Result<Page<T>>;

abstract class Page<T> {
  Page({
    required this.number,
    required this.totalPages,
    required this.data,
  });

  final int number;
  final int totalPages;
  final List<T> data;
}
