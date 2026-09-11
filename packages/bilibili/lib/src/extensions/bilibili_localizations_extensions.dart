import 'package:flutter/widgets.dart';

import '../../l10n/localization_file/bilibili_localizations.dart';
import '../category.dart';
import '../data/source/bili_remote_data_source.dart';
import '../search/search_filter.dart';
import '../search/sort.dart';

extension BilibiliBuildContextX on BuildContext {
  BilibiliLocalizations get biliL10n {
    final l10n = BilibiliLocalizations.of(this);
    assert(
      l10n != null,
      'No BilibiliLocalizations found in context. Make sure BilibiliLocalizations.delegate is included in localizationsDelegates.',
    );
    return l10n!;
  }
}

extension BilibiliSourceX on BiliRemoteDataSource {
  String localizedSourceName(BuildContext context) =>
      context.biliL10n.sourceName;
}

extension VideoDurationFilterOptionX on VideoDurationFilterOption {
  String localizedLabel(BuildContext context) =>
      labelWithL10n(context.biliL10n);

  String labelWithL10n(BilibiliLocalizations l10n) => switch (this) {
    VideoDurationFilterOption.allDuration => l10n.videoDurationAll,
    VideoDurationFilterOption.below10Minutes => l10n.videoDurationUnder10Min,
    VideoDurationFilterOption.tenTo30Minutes => l10n.videoDuration10To30Min,
    VideoDurationFilterOption.thirtyTo60Minutes => l10n.videoDuration30To60Min,
    VideoDurationFilterOption.above60Minutes => l10n.videoDurationOver60Min,
  };
}

extension UserTypeX on UserType {
  String localizedLabel(BuildContext context) =>
      labelWithL10n(context.biliL10n);

  String labelWithL10n(BilibiliLocalizations l10n) => switch (this) {
    UserType.allUsers => l10n.userTypeAll,
    UserType.upMain => l10n.userTypeUp,
    UserType.normalUser => l10n.userTypeNormal,
    UserType.verifiedUser => l10n.userTypeVerified,
  };
}

extension ArticleCategoryX on ArticleCategory {
  String localizedLabel(BuildContext context) =>
      labelWithL10n(context.biliL10n);

  String labelWithL10n(BilibiliLocalizations l10n) => switch (this) {
    ArticleCategory.all => l10n.articleCategoryAll,
    ArticleCategory.animation => l10n.articleCategoryAnimation,
    ArticleCategory.games => l10n.articleCategoryGames,
    ArticleCategory.movies => l10n.articleCategoryMovies,
    ArticleCategory.life => l10n.articleCategoryLife,
    ArticleCategory.interests => l10n.articleCategoryInterests,
    ArticleCategory.lightNovels => l10n.articleCategoryLightNovels,
    ArticleCategory.technology => l10n.articleCategoryTechnology,
  };
}

extension PhotoCategoryX on PhotoCategory {
  String localizedLabel(BuildContext context) =>
      labelWithL10n(context.biliL10n);

  String labelWithL10n(BilibiliLocalizations l10n) => switch (this) {
    PhotoCategory.all => l10n.photoCategoryAll,
    PhotoCategory.artists => l10n.photoCategoryArtists,
    PhotoCategory.photography => l10n.photoCategoryPhotography,
  };
}

extension ArticleSearchSortX on ArticleSearchSort {
  String localizedLabel(BuildContext context) =>
      labelWithL10n(context.biliL10n);

  String labelWithL10n(BilibiliLocalizations l10n) => switch (this) {
    ArticleSearchSort.totalrank => l10n.sortTotalRank,
    ArticleSearchSort.attention => l10n.sortAttention,
    ArticleSearchSort.click => l10n.sortClick,
    ArticleSearchSort.dm => l10n.sortDm,
    ArticleSearchSort.pubdate => l10n.sortPubDate,
    ArticleSearchSort.scores => l10n.sortScores,
    ArticleSearchSort.stow => l10n.sortStow,
  };
}

extension PhotoOrVideoSearchSortX on PhotoOrVideoSearchSort {
  String localizedLabel(BuildContext context) =>
      labelWithL10n(context.biliL10n);

  String labelWithL10n(BilibiliLocalizations l10n) => switch (this) {
    PhotoOrVideoSearchSort.totalrank => l10n.sortTotalRank,
    PhotoOrVideoSearchSort.click => l10n.sortClick,
    PhotoOrVideoSearchSort.dm => l10n.sortDm,
    PhotoOrVideoSearchSort.pubdate => l10n.sortPubDate,
    PhotoOrVideoSearchSort.scores => l10n.sortScores,
    PhotoOrVideoSearchSort.stow => l10n.sortStow,
  };
}

extension LiveRoomSearchSortX on LiveRoomSearchSort {
  String localizedLabel(BuildContext context) =>
      labelWithL10n(context.biliL10n);

  String labelWithL10n(BilibiliLocalizations l10n) => switch (this) {
    LiveRoomSearchSort.online => l10n.sortOnline,
    LiveRoomSearchSort.liveTime => l10n.sortLiveTime,
  };
}

extension UserSearchSortX on UserSearchSort {
  String localizedLabel(BuildContext context) =>
      labelWithL10n(context.biliL10n);

  String labelWithL10n(BilibiliLocalizations l10n) => switch (this) {
    UserSearchSort.defaultSort => l10n.sortDefault,
    UserSearchSort.fonsDescending => l10n.sortFansDesc,
    UserSearchSort.fonsAscending => l10n.sortFansAsc,
    UserSearchSort.levelDescending => l10n.sortLevelDesc,
    UserSearchSort.levelAscending => l10n.sortLevelAsc,
  };
}
