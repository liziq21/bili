import 'package:flutter/widgets.dart';

import '../../l10n/localization_file/youtube_localizations.dart';
import '../data/source/youtube_remote_data_source.dart';
import '../search/search_filter.dart';
import '../search/sort.dart';
import '../youtube.dart';

extension YoutubeBuildContextX on BuildContext {
  YoutubeLocalizations get youtubeL10n {
    final l10n = YoutubeLocalizations.of(this);
    assert(
      l10n != null,
      'No YoutubeLocalizations found in context. Make sure YoutubeLocalizations.delegate is included in localizationsDelegates.',
    );
    return l10n!;
  }
}

extension YouTubeSourceX on YouTube {
  String localizedSourceName(BuildContext context) =>
      context.youtubeL10n.sourceName;
}

extension YouTubeRemoteDataSourceX on YouTubeRemoteDataSource {
  String localizedSourceName(BuildContext context) =>
      context.youtubeL10n.sourceName;
}

extension YoutubeSearchSortX on YoutubeSearchSort {
  String localizedLabel(BuildContext context) =>
      labelWithL10n(context.youtubeL10n);

  String labelWithL10n(YoutubeLocalizations l10n) => switch (this) {
    YoutubeSearchSort.relevance => l10n.sortRelevance,
    YoutubeSearchSort.uploadDate => l10n.sortUploadDate,
    YoutubeSearchSort.viewCount => l10n.sortViewCount,
    YoutubeSearchSort.rating => l10n.sortRating,
  };
}

extension YoutubeUploadDateFilterOptionX on YoutubeUploadDateFilterOption {
  String localizedLabel(BuildContext context) =>
      labelWithL10n(context.youtubeL10n);

  String labelWithL10n(YoutubeLocalizations l10n) => switch (this) {
    YoutubeUploadDateFilterOption.lastHour => l10n.uploadDateLastHour,
    YoutubeUploadDateFilterOption.today => l10n.uploadDateToday,
    YoutubeUploadDateFilterOption.thisWeek => l10n.uploadDateThisWeek,
    YoutubeUploadDateFilterOption.thisMonth => l10n.uploadDateThisMonth,
    YoutubeUploadDateFilterOption.thisYear => l10n.uploadDateThisYear,
  };
}

extension YoutubeContentTypeFilterOptionX on YoutubeContentTypeFilterOption {
  String localizedLabel(BuildContext context) =>
      labelWithL10n(context.youtubeL10n);

  String labelWithL10n(YoutubeLocalizations l10n) => switch (this) {
    YoutubeContentTypeFilterOption.video => l10n.contentTypeVideo,
    YoutubeContentTypeFilterOption.channel => l10n.contentTypeChannel,
    YoutubeContentTypeFilterOption.playlist => l10n.contentTypePlaylist,
    YoutubeContentTypeFilterOption.movie => l10n.contentTypeMovie,
  };
}

extension YoutubeDurationFilterOptionX on YoutubeDurationFilterOption {
  String localizedLabel(BuildContext context) =>
      labelWithL10n(context.youtubeL10n);

  String labelWithL10n(YoutubeLocalizations l10n) => switch (this) {
    YoutubeDurationFilterOption.under4Minutes => l10n.durationUnder4Minutes,
    YoutubeDurationFilterOption.fourTo20Minutes => l10n.duration4To20Minutes,
    YoutubeDurationFilterOption.over20Minutes => l10n.durationOver20Minutes,
  };
}

extension YoutubeFeatureFilterOptionX on YoutubeFeatureFilterOption {
  String localizedLabel(BuildContext context) =>
      labelWithL10n(context.youtubeL10n);

  String labelWithL10n(YoutubeLocalizations l10n) => switch (this) {
    YoutubeFeatureFilterOption.live => l10n.featureLive,
    YoutubeFeatureFilterOption.fourK => l10n.feature4K,
    YoutubeFeatureFilterOption.hd => l10n.featureHD,
    YoutubeFeatureFilterOption.subtitles => l10n.featureSubtitles,
    YoutubeFeatureFilterOption.creativeCommons => l10n.featureCreativeCommons,
    YoutubeFeatureFilterOption.threeD => l10n.feature3D,
    YoutubeFeatureFilterOption.threeSixty => l10n.feature360,
    YoutubeFeatureFilterOption.hdr => l10n.featureHDR,
  };
}

extension YoutubeUploadDateFilterGroupX on YoutubeUploadDateFilterGroup {
  String localizedLabel(BuildContext context) =>
      labelWithL10n(context.youtubeL10n);

  String labelWithL10n(YoutubeLocalizations l10n) => l10n.filterGroupUploadDate;
}

extension YoutubeDurationFilterGroupX on YoutubeDurationFilterGroup {
  String localizedLabel(BuildContext context) =>
      labelWithL10n(context.youtubeL10n);

  String labelWithL10n(YoutubeLocalizations l10n) => l10n.filterGroupDuration;
}

extension YoutubeFeatureFilterGroupX on YoutubeFeatureFilterGroup {
  String localizedLabel(BuildContext context) =>
      labelWithL10n(context.youtubeL10n);

  String labelWithL10n(YoutubeLocalizations l10n) => l10n.filterGroupFeature;
}
