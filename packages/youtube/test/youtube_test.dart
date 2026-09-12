import 'package:data/data.dart';
import 'package:test/test.dart';
import 'package:youtube/youtube.dart';

void main() {
  group('YouTube Package Initializer Tests', () {
    test(
      'YouTube facade creates RemoteDataSources with sourceId "youtube"',
      () {
        final youtube = YouTube();

        final videoDS = youtube.videoSearchDataSource();
        final creatorDS = youtube.creatorProfileSearchDataSource();
        final suggestDS = youtube.searchSuggestDataSource();

        expect(videoDS, isA<VideoSearchRemoteDataSource>());
        expect(creatorDS, isA<CreatorProfileSearchRemoteDataSource>());
        expect(suggestDS, isA<SearchSuggestRemoteDataSource>());

        expect(videoDS.sourceId, equals('youtube'));
        expect(creatorDS.sourceId, equals('youtube'));
        expect(suggestDS.sourceId, equals('youtube'));

        youtube.close();
      },
    );
  });
}
