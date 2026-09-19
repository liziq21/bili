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
      final suggests = await _youtubeService.getSearchSuggestions(query);
      return Result.ok(suggests);
    } catch (e) {
      return Result.error(e is Exception ? e : Exception(e.toString()));
    }
  }
}
