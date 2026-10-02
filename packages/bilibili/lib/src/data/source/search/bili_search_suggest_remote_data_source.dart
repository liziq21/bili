import 'dart:async';

import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:model/model.dart';

import '../bili_remote_data_source.dart';

final class const BiliSearchSuggestRemoteDataSource({
  required final NetworkSearchDataSource network,
}) extends SearchSuggestRemoteDataSource with BiliRemoteDataSource {
  static final RegExp _controlChars = RegExp(r'[\x00-\x1F\x7F]');

  @override
  Future<Result<List<String>>> getSuggests(String query) {
    final sanitizedQuery = query.replaceAll(_controlChars, '').trim();
    if (sanitizedQuery.isEmpty) {
      return Future.value(const Result.ok([]));
    }
    return network
        .getSuggests(sanitizedQuery)
        .then(
          (value) => value.tag
              .map(
                // `term` is plain text: in the captured `search_suggest.json`
                // response all 10 entries carry HTML highlight markup in `name`
                // and none in `term`. Stripping tags from `term` would instead
                // corrupt literal queries such as `a < b > c`.
                (e) => e.term.replaceAll(_controlChars, ''),
              )
              .where((term) => term.isNotEmpty)
              .toList(),
        )
        .toResult();
  }
}
