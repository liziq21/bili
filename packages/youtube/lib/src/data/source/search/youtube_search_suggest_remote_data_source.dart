import 'dart:async';

import 'package:data/data.dart';
import 'package:model/model.dart';
import 'package:ypi/ypi.dart';

import '../youtube_remote_data_source.dart';

final class const YouTubeSearchSuggestRemoteDataSource(
  final YoutubeService _youtubeService,
) extends SearchSuggestRemoteDataSource with YouTubeRemoteDataSource {
  @override
  Future<Result<List<String>>> getSuggests(String query) async {
    try {
      final response = await _youtubeService.getSearchSuggestions(query);
      return Result.ok(response.suggestions);
    } catch (error) {
      return Result.error(
        error is Exception ? error : Exception(error.toString()),
      );
    }
  }
}
