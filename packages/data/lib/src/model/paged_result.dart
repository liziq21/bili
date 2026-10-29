import 'package:model/model.dart';

typedef PagedResult<T> = Result<Page<T>, Exception>;

class Page<T>({
  required final int number,
  required final int totalPages,
  required final List<T> data,
});
