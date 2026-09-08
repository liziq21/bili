import 'package:model/model.dart';

typedef PagedResult<T> = Result<Page<T>>;

class Page<T> {
  const Page({
    required this.number,
    required this.totalPages,
    required this.data,
  });

  final int number;
  final int totalPages;
  final List<T> data;
}
