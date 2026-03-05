abstract class PagedResult<T> {
  PagedResult({
    required this.page,
    required this.totalPages,
    required this.data,
  });

  final int page;
  final int totalPages;
  final List<T> data;
}
