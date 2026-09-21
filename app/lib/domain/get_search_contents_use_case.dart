import 'dart:async';

import 'package:data/data.dart';
import 'package:model/model.dart';

import '../data/repository/search_contents_repository.dart';

/// 搜索内容用例 (Domain Use Case)
///
/// 封装针对具体 [SearchContentsRepository] 执行的搜索逻辑。
class GetSearchContentsUseCase<T>({
  required final SearchContentsRepository<T> _repository,
}) {
  /// 执行搜索请求并返回包含分页数据的 [Result]
  Future<Result<Page<T>>> invoke(SearchQuery query) =>
      _repository.search(query);
}
