import 'package:bilibili/bilibili.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BilibiliLocalizations tests', () {
    test('loads zh localizations correctly', () {
      final l10n = lookupBilibiliLocalizations(const Locale('zh'));
      expect(l10n.sourceName, '哔哩哔哩');
      expect(l10n.videoDurationAll, '不限');
      expect(l10n.videoDurationUnder10Min, '10分钟以下');
      expect(l10n.userTypeUp, 'UP主');
      expect(l10n.articleCategoryAnimation, '动画');
      expect(l10n.photoCategoryArtists, '画师');
      expect(l10n.sortTotalRank, '综合排序');
      expect(l10n.sortOnline, '人气排序');
      expect(l10n.sortFansDesc, '粉丝数从高到低');
    });

    test('loads en localizations correctly', () {
      final l10n = lookupBilibiliLocalizations(const Locale('en'));
      expect(l10n.sourceName, 'Bilibili');
      expect(l10n.videoDurationAll, 'All');
      expect(l10n.videoDurationUnder10Min, 'Under 10 minutes');
      expect(l10n.userTypeUp, 'UP Host');
      expect(l10n.articleCategoryAnimation, 'Animation');
      expect(l10n.photoCategoryArtists, 'Artists');
      expect(l10n.sortTotalRank, 'Most Relevant');
      expect(l10n.sortOnline, 'Popularity');
      expect(l10n.sortFansDesc, 'Followers (High to Low)');
    });

    test('enum extensions return correct localized labels', () {
      final zhL10n = lookupBilibiliLocalizations(const Locale('zh'));
      final enL10n = lookupBilibiliLocalizations(const Locale('en'));

      expect(
        VideoDurationFilterOption.below10Minutes.labelWithL10n(zhL10n),
        '10分钟以下',
      );
      expect(
        VideoDurationFilterOption.below10Minutes.labelWithL10n(enL10n),
        'Under 10 minutes',
      );

      expect(UserType.upMain.labelWithL10n(zhL10n), 'UP主');
      expect(UserType.upMain.labelWithL10n(enL10n), 'UP Host');

      expect(ArticleCategory.games.labelWithL10n(zhL10n), '游戏');
      expect(ArticleCategory.games.labelWithL10n(enL10n), 'Games');

      expect(PhotoCategory.photography.labelWithL10n(zhL10n), '摄影');
      expect(PhotoCategory.photography.labelWithL10n(enL10n), 'Photography');

      expect(ArticleSearchSort.click.labelWithL10n(zhL10n), '最多点击');
      expect(ArticleSearchSort.click.labelWithL10n(enL10n), 'Most Viewed');

      expect(LiveRoomSearchSort.liveTime.labelWithL10n(zhL10n), '开播时间');
      expect(
        LiveRoomSearchSort.liveTime.labelWithL10n(enL10n),
        'Live Start Time',
      );

      expect(UserSearchSort.levelDescending.labelWithL10n(zhL10n), '等级从高到低');
      expect(
        UserSearchSort.levelDescending.labelWithL10n(enL10n),
        'Level (High to Low)',
      );
    });
  });
}
