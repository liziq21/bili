import 'dart:async';

import 'package:data/data.dart';
import 'package:model/model.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../youtube_remote_data_source.dart';

final class const YouTubeSearchSuggestRemoteDataSource({
  required final YoutubeExplode _youtubeExplode,
}) extends SearchSuggestRemoteDataSource with YouTubeRemoteDataSource {
  @override
  Future<Result<List<String>>> getSuggests(String query) async {
    try {
      final suggestions = await _youtubeExplode.search.getQuerySuggestions(
        query,
      );
      return Result.ok(suggestions);
    } catch (e, st) {
      return Result.error(Exception('$e\n$st'));
    }
  }
}
