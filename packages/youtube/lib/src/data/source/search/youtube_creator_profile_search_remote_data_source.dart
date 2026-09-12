import 'dart:async';

import 'package:data/data.dart';
import 'package:model/model.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../youtube_remote_data_source.dart';

final class const YouTubeCreatorProfileSearchRemoteDataSource({
  required final YoutubeExplode _youtubeExplode,
}) extends CreatorProfileSearchRemoteDataSource with YouTubeRemoteDataSource {
  //@override
  //List<FilterGroup> get filters => const [];

  @override
  List<SortOption> get sortOptions => const [];

  @override
  Future<Result<Page<CreatorProfile>>> searchCreatorProfile(
    String query, {
    int? pageKey,
  }) async {
    try {
      final targetPage = pageKey ?? 1;
      final searchList = await _youtubeExplode.search.searchContent(
        query,
        filter: TypeFilters.channel,
      );

      SearchList currentList = searchList;
      for (int i = 1; i < targetPage; i++) {
        final nextPage = await currentList.nextPage();
        if (nextPage == null) {
          return Result.ok(
            Page<CreatorProfile>(
              number: targetPage,
              totalPages: targetPage,
              data: const [],
            ),
          );
        }
        currentList = nextPage;
      }

      final profiles = currentList.whereType<SearchChannel>().map((channel) {
        return CreatorProfile(
          id: channel.id.value,
          name: channel.name,
          videos: channel.videoCount,
        );
      }).toList();

      final totalPages = currentList.isNotEmpty ? targetPage + 1 : targetPage;

      return Result.ok(
        Page<CreatorProfile>(
          number: targetPage,
          totalPages: totalPages,
          data: profiles,
        ),
      );
    } catch (e, st) {
      return Result.error(Exception('$e\n$st'));
    }
  }
}
