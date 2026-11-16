import 'package:data/data.dart';
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
  /// The source's display name in the active locale.
  String localizedSourceName(BuildContext context) =>
      localizedName(context.youtubeL10n);

  /// The source's display name in [l10n].
  String localizedName(YoutubeLocalizations l10n) => l10n.sourceName;
}

extension YouTubeRemoteDataSourceX on YouTubeRemoteDataSource {
  /// The source's display name in the active locale.
  String localizedSourceName(BuildContext context) =>
      localizedName(context.youtubeL10n);

  /// The source's display name in [l10n].
  String localizedName(YoutubeLocalizations l10n) => l10n.sourceName;
}

extension YoutubeSearchSortX on YoutubeSearchSort {
  /// The localized label in the active locale.
  String localizedLabel(BuildContext context) =>
      labelWithL10n(context.youtubeL10n);

  /// The localized label in [l10n].
  String labelWithL10n(YoutubeLocalizations l10n) => switch (this) {
    YoutubeSearchSort.relevance => l10n.sortRelevance,
    YoutubeSearchSort.uploadDate => l10n.sortUploadDate,
    YoutubeSearchSort.viewCount => l10n.sortViewCount,
    YoutubeSearchSort.rating => l10n.sortRating,
  };
}

extension YoutubeUploadDateFilterOptionX on YoutubeUploadDateFilterOption {
  /// The localized label in the active locale.
  String localizedLabel(BuildContext context) =>
      labelWithL10n(context.youtubeL10n);

  /// The localized label in [l10n].
  String labelWithL10n(YoutubeLocalizations l10n) => switch (this) {
    YoutubeUploadDateFilterOption.lastHour => l10n.uploadDateLastHour,
    YoutubeUploadDateFilterOption.today => l10n.uploadDateToday,
    YoutubeUploadDateFilterOption.thisWeek => l10n.uploadDateThisWeek,
    YoutubeUploadDateFilterOption.thisMonth => l10n.uploadDateThisMonth,
    YoutubeUploadDateFilterOption.thisYear => l10n.uploadDateThisYear,
  };
}

extension YoutubeContentTypeFilterOptionX on YoutubeContentTypeFilterOption {
  /// The localized label in the active locale.
  String localizedLabel(BuildContext context) =>
      labelWithL10n(context.youtubeL10n);

  /// The localized label in [l10n].
  String labelWithL10n(YoutubeLocalizations l10n) => switch (this) {
    YoutubeContentTypeFilterOption.video => l10n.contentTypeVideo,
    YoutubeContentTypeFilterOption.channel => l10n.contentTypeChannel,
    YoutubeContentTypeFilterOption.playlist => l10n.contentTypePlaylist,
    YoutubeContentTypeFilterOption.movie => l10n.contentTypeMovie,
  };
}

extension YoutubeDurationFilterOptionX on YoutubeDurationFilterOption {
  /// The localized label in the active locale.
  String localizedLabel(BuildContext context) =>
      labelWithL10n(context.youtubeL10n);

  /// The localized label in [l10n].
  String labelWithL10n(YoutubeLocalizations l10n) => switch (this) {
    YoutubeDurationFilterOption.under4Minutes => l10n.durationUnder4Minutes,
    YoutubeDurationFilterOption.fourTo20Minutes => l10n.duration4To20Minutes,
    YoutubeDurationFilterOption.over20Minutes => l10n.durationOver20Minutes,
  };
}

extension YoutubeFeatureFilterOptionX on YoutubeFeatureFilterOption {
  /// The localized label in the active locale.
  String localizedLabel(BuildContext context) =>
      labelWithL10n(context.youtubeL10n);

  /// The localized label in [l10n].
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
  /// The localized group title in the active locale.
  String localizedLabel(BuildContext context) =>
      labelWithL10n(context.youtubeL10n);

  /// The localized group title in [l10n].
  String labelWithL10n(YoutubeLocalizations l10n) => l10n.filterGroupUploadDate;
}

extension YoutubeDurationFilterGroupX on YoutubeDurationFilterGroup {
  /// The localized group title in the active locale.
  String localizedLabel(BuildContext context) =>
      labelWithL10n(context.youtubeL10n);

  /// The localized group title in [l10n].
  String labelWithL10n(YoutubeLocalizations l10n) => l10n.filterGroupDuration;
}

extension YoutubeFeatureFilterGroupX on YoutubeFeatureFilterGroup {
  /// The localized group title in the active locale.
  String localizedLabel(BuildContext context) =>
      labelWithL10n(context.youtubeL10n);

  /// The localized group title in [l10n].
  String labelWithL10n(YoutubeLocalizations l10n) => l10n.filterGroupFeature;
}

/// The localized label of any filter option in [l10n].
///
/// YouTube options resolve through their ARB entries; anything else falls back
/// to its neutral [FilterOption.label], which is already display copy for
/// sources that do not ship their own localization package.
String localizedOptionLabel(FilterOption option, YoutubeLocalizations l10n) =>
    switch (option) {
      final YoutubeUploadDateFilterOption o => o.labelWithL10n(l10n),
      final YoutubeContentTypeFilterOption o => o.labelWithL10n(l10n),
      final YoutubeDurationFilterOption o => o.labelWithL10n(l10n),
      final YoutubeFeatureFilterOption o => o.labelWithL10n(l10n),
      _ => option.label,
    };

/// The localized title of any filter group in [l10n]. See
/// [localizedOptionLabel] for the fallback rule.
String localizedGroupLabel(FilterGroup group, YoutubeLocalizations l10n) =>
    switch (group) {
      // The filter sheet replaces list entries with neutral SingleFilterGroup
      // copies, so the YouTube key is what identifies them after a pick.
      FilterGroup(key: YoutubeFilterKey.uploadDate) =>
        l10n.filterGroupUploadDate,
      FilterGroup(key: YoutubeFilterKey.duration) => l10n.filterGroupDuration,
      FilterGroup(key: YoutubeFilterKey.feature) => l10n.filterGroupFeature,
      final YoutubeUploadDateFilterGroup g => g.labelWithL10n(l10n),
      final YoutubeDurationFilterGroup g => g.labelWithL10n(l10n),
      final YoutubeFeatureFilterGroup g => g.labelWithL10n(l10n),
      _ => group.label,
    };

/// The localized label of any sort option in [l10n]. See
/// [localizedOptionLabel] for the fallback rule.
String localizedSortLabel(SortOption option, YoutubeLocalizations l10n) =>
    switch (option) {
      final YoutubeSearchSort o => o.labelWithL10n(l10n),
      _ => option.label,
    };

extension LocalizedFilterOptionX on FilterOption {
  /// The localized label in the active locale.
  String localizedLabel(BuildContext context) =>
      localizedOptionLabel(this, context.youtubeL10n);
}

extension LocalizedFilterGroupX on FilterGroup {
  /// The localized group title in the active locale.
  String localizedLabel(BuildContext context) =>
      localizedGroupLabel(this, context.youtubeL10n);
}

extension LocalizedSortOptionX on SortOption {
  /// The localized label in the active locale.
  String localizedLabel(BuildContext context) =>
      localizedSortLabel(this, context.youtubeL10n);
}
