import 'dart:async';

import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:model/model.dart';

import '../bili_remote_data_source.dart';

final class const BiliSearchSuggestRemoteDataSource({
  required final NetworkSearchDataSource network,
}) extends SearchSuggestRemoteDataSource with BiliRemoteDataSource {
  static final RegExp _controlChars = RegExp(r'[\x00-\x1F\x7F]');
  static final RegExp _htmlTags = RegExp(r'<[^>]*>');

  @override
  Future<Result<List<String>>> getSuggests(String query) {
    final sanitizedQuery = query.replaceAll(_controlChars, '');
    if (sanitizedQuery.isEmpty) {
      return Future.value(const Result.ok([]));
    }
    return network
        .getSuggests(sanitizedQuery)
        .then(
          (value) => value.tag
              .map(
                (e) => e.term
                    .replaceAll(_htmlTags, '')
                    .replaceAll(_controlChars, ''),
              )
              .where((term) => term.isNotEmpty)
              .toList(),
        )
        .toResult();
  }
}
