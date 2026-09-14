import 'dart:async';

import 'package:data/data.dart';
import 'package:model/model.dart';
import 'package:ypi/ypi.dart';

import '../youtube_remote_data_source.dart';

final class const YouTubeSearchSuggestRemoteDataSource({
  required final YoutubeService _youtubeService,
}) extends SearchSuggestRemoteDataSource with YouTubeRemoteDataSource {
  @override
  Future<Result<List<String>>> getSuggests(String query) async {
    try {
      final suggestions = await _youtubeService.getSearchSuggestions(query);
      return Result.ok(suggestions);
    } catch (e, st) {
      return Result.error(Exception('$e\n$st'));
    }
  }
}
