import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:youtube/youtube.dart';
import 'package:app/data/repository/search/app_youtube_video_search_repository.dart';

void main() {
  group('AppYouTubeVideoSearchRepository Tests', () {
    test('exposes sortOptions and filters from YouTubeVideoSearchRemoteDataSource', () {
      final mockClient = MockClient((_) async => http.Response('{}', 200));
      final youtubeService = YoutubeService(httpClient: mockClient);
      final remoteDS = YouTubeVideoSearchRemoteDataSource(youtubeService: youtubeService);
      final repo = AppYouTubeVideoSearchRepository(remoteDS);

      expect(repo.sortOptions, equals(remoteDS.sortOptions));
      expect(repo.filters, equals(remoteDS.filters));

      youtubeService.close();
    });
  });
}
