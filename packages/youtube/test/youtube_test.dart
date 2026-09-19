import 'package:data/data.dart';
import 'package:flutter/widgets.dart' hide Page;
import 'package:model/model.dart';
import 'package:test/test.dart';
import 'package:youtube/youtube.dart';

void main() {
  group('YouTube Package Initializer Tests', () {
    test('YouTube facade creates RemoteDataSources with sourceId "youtube" and exposes sort & filter options', () {
      final youtube = YouTube();

      final videoDS = youtube.videoSearchDataSource;
      final creatorDS = youtube.creatorProfileSearchDataSource;
      final suggestDS = youtube.searchSuggestDataSource;

      expect(videoDS, isA<VideoSearchRemoteDataSource>());
      expect(creatorDS, isA<CreatorProfileSearchRemoteDataSource>());
      expect(suggestDS, isA<SearchSuggestRemoteDataSource>());

      expect(videoDS.sourceId, equals('youtube'));
      expect(creatorDS.sourceId, equals('youtube'));
      expect(suggestDS.sourceId, equals('youtube'));

      expect(videoDS.sortOptions, isNotEmpty);
      expect(videoDS.sortOptions.length, equals(4));

      expect(videoDS.filters, isNotEmpty);
      expect(videoDS.filters.length, equals(3));

      youtube.close();
    });

    test('Remote data sources sanitize error handling and do not leak stack traces into Result.error', () async {
      final youtube = YouTube();

      final ds = youtube.videoSearchDataSource as YouTubeVideoSearchRemoteDataSource;
      final videoRes = await ds.searchVideoWithOptions(
        SearchQuery(
          query: 'test',
          pageKey: 1,
          filters: const [
            SingleFilterGroup(
              key: 'upload_date',
              label: 'invalid',
              options: [YoutubeUploadDateFilterOption.today],
              selection: YoutubeUploadDateFilterOption.today,
            ),
          ],
        ),
      );
      expect(videoRes, isA<Result<Page<VideoModel>>>());
      if (videoRes is Error) {
        expect(videoRes.toString(), isNot(contains('\n#0')));
      }

      youtube.close();
    });

    test('Search sort and filter options localize correctly in Chinese (zh) and English (en)', () {
      final zh = lookupYoutubeLocalizations(const Locale('zh'));
      final en = lookupYoutubeLocalizations(const Locale('en'));

      // Sort option localization
      expect(YoutubeSearchSort.relevance.labelWithL10n(zh), equals('相关性'));
      expect(
        YoutubeSearchSort.relevance.labelWithL10n(en),
        equals('Relevance'),
      );

      expect(YoutubeSearchSort.uploadDate.labelWithL10n(zh), equals('上传时间'));
      expect(
        YoutubeSearchSort.uploadDate.labelWithL10n(en),
        equals('Upload date'),
      );

      expect(YoutubeSearchSort.viewCount.labelWithL10n(zh), equals('播放量'));
      expect(
        YoutubeSearchSort.viewCount.labelWithL10n(en),
        equals('View count'),
      );

      expect(YoutubeSearchSort.rating.labelWithL10n(zh), equals('评分'));
      expect(YoutubeSearchSort.rating.labelWithL10n(en), equals('Rating'));

      // Filter option localization
      expect(
        YoutubeUploadDateFilterOption.today.labelWithL10n(zh),
        equals('今天'),
      );
      expect(
        YoutubeUploadDateFilterOption.today.labelWithL10n(en),
        equals('Today'),
      );

      expect(
        YoutubeDurationFilterOption.under4Minutes.labelWithL10n(zh),
        equals('4分钟以下'),
      );
      expect(
        YoutubeDurationFilterOption.under4Minutes.labelWithL10n(en),
        equals('Under 4 minutes'),
      );

      expect(YoutubeFeatureFilterOption.live.labelWithL10n(zh), equals('直播'));
      expect(YoutubeFeatureFilterOption.live.labelWithL10n(en), equals('Live'));

      // Filter group title localization
      const uploadGroup = YoutubeUploadDateFilterGroup();
      const durationGroup = YoutubeDurationFilterGroup();
      const featureGroup = YoutubeFeatureFilterGroup();

      expect(uploadGroup.labelWithL10n(zh), equals('上传时间'));
      expect(uploadGroup.labelWithL10n(en), equals('Upload date'));

      expect(durationGroup.labelWithL10n(zh), equals('视频时长'));
      expect(durationGroup.labelWithL10n(en), equals('Duration'));

      expect(featureGroup.labelWithL10n(zh), equals('功能特性'));
      expect(featureGroup.labelWithL10n(en), equals('Features'));
    });
  });
}
