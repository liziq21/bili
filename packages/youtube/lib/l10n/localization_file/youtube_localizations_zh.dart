// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'youtube_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class YoutubeLocalizationsZh extends YoutubeLocalizations {
  YoutubeLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get sourceName => 'YouTube';

  @override
  String get filterGroupUploadDate => '上传时间';

  @override
  String get filterGroupDuration => '视频时长';

  @override
  String get filterGroupFeature => '功能特性';

  @override
  String get sortRelevance => '相关性';

  @override
  String get sortUploadDate => '上传时间';

  @override
  String get sortViewCount => '播放量';

  @override
  String get sortRating => '评分';

  @override
  String get uploadDateLastHour => '1小时内';

  @override
  String get uploadDateToday => '今天';

  @override
  String get uploadDateThisWeek => '本周';

  @override
  String get uploadDateThisMonth => '本月';

  @override
  String get uploadDateThisYear => '本年';

  @override
  String get durationUnder4Minutes => '4分钟以下';

  @override
  String get duration4To20Minutes => '4-20分钟';

  @override
  String get durationOver20Minutes => '20分钟以上';

  @override
  String get featureLive => '直播';

  @override
  String get feature4K => '4K';

  @override
  String get featureHD => '高清';

  @override
  String get featureSubtitles => '字幕/CC';

  @override
  String get featureCreativeCommons => '知识共享';

  @override
  String get feature3D => '3D';

  @override
  String get feature360 => '360°';

  @override
  String get featureHDR => 'HDR';

  @override
  String get contentTypeVideo => '视频';

  @override
  String get contentTypeChannel => '频道';

  @override
  String get contentTypePlaylist => '播放列表';

  @override
  String get contentTypeMovie => '电影';
}
