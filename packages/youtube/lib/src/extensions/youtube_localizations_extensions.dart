import 'package:flutter/widgets.dart';
import 'package:ypi/ypi.dart';

import '../../l10n/localization_file/youtube_localizations.dart';
import '../data/source/youtube_remote_data_source.dart';
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

extension YoutubeUploadDateFilterX on YoutubeUploadDateFilter {
  String localizedLabel(BuildContext context) =>
      labelWithL10n(context.youtubeL10n);

  String labelWithL10n(YoutubeLocalizations l10n) => switch (this) {
    YoutubeUploadDateFilter.lastHour => l10n.uploadDateLastHour,
    YoutubeUploadDateFilter.today => l10n.uploadDateToday,
    YoutubeUploadDateFilter.thisWeek => l10n.uploadDateThisWeek,
    YoutubeUploadDateFilter.thisMonth => l10n.uploadDateThisMonth,
    YoutubeUploadDateFilter.thisYear => l10n.uploadDateThisYear,
  };
}

extension YoutubeContentTypeFilterX on YoutubeContentTypeFilter {
  String localizedLabel(BuildContext context) =>
      labelWithL10n(context.youtubeL10n);

  String labelWithL10n(YoutubeLocalizations l10n) => switch (this) {
    YoutubeContentTypeFilter.video => l10n.contentTypeVideo,
    YoutubeContentTypeFilter.channel => l10n.contentTypeChannel,
    YoutubeContentTypeFilter.playlist => l10n.contentTypePlaylist,
    YoutubeContentTypeFilter.movie => l10n.contentTypeMovie,
  };
}

extension YoutubeDurationFilterX on YoutubeDurationFilter {
  String localizedLabel(BuildContext context) =>
      labelWithL10n(context.youtubeL10n);

  String labelWithL10n(YoutubeLocalizations l10n) => switch (this) {
    YoutubeDurationFilter.under4Minutes => l10n.durationUnder4Minutes,
    YoutubeDurationFilter.fourTo20Minutes => l10n.duration4To20Minutes,
    YoutubeDurationFilter.over20Minutes => l10n.durationOver20Minutes,
  };
}

extension YoutubeFeatureFilterX on YoutubeFeatureFilter {
  String localizedLabel(BuildContext context) =>
      labelWithL10n(context.youtubeL10n);

  String labelWithL10n(YoutubeLocalizations l10n) => switch (this) {
    YoutubeFeatureFilter.live => l10n.featureLive,
    YoutubeFeatureFilter.fourK => l10n.feature4K,
    YoutubeFeatureFilter.hd => l10n.featureHD,
    YoutubeFeatureFilter.subtitles => l10n.featureSubtitles,
    YoutubeFeatureFilter.creativeCommons => l10n.featureCreativeCommons,
    YoutubeFeatureFilter.threeD => l10n.feature3D,
    YoutubeFeatureFilter.threeSixty => l10n.feature360,
    YoutubeFeatureFilter.hdr => l10n.featureHDR,
  };
}
