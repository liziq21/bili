import 'dart:async';

import 'package:data/data.dart';
import 'package:model/model.dart';
import 'package:ypi/ypi.dart';

import '../youtube_remote_data_source.dart';

final class YouTubeSearchSuggestRemoteDataSource(
  final YoutubeService _youtubeService,
) extends SearchSuggestRemoteDataSource with YouTubeRemoteDataSource {
  static final RegExp _controlChars = RegExp(r'[\x00-\x1F\x7F]');

  @override
  Future<Result<List<String>, Exception>> getSuggests(String query) async {
    final sanitizedQuery = query.replaceAll(_controlChars, '').trim();
    if (sanitizedQuery.isEmpty) {
      return const Result.success([]);
    }
    try {
      final response = await _youtubeService.getSearchSuggestions(
        sanitizedQuery,
      );
      final sanitizedSuggestions = response.suggestions
          .map((s) => s.replaceAll(_controlChars, ''))
          .where((s) => s.isNotEmpty)
          .toList();
      return Result.success(sanitizedSuggestions);
    } catch (error) {
      return Result.error(
        error is Exception ? error : Exception(error.toString()),
      );
    }
  }
}
