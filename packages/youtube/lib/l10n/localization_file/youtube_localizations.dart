import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'youtube_localizations_en.dart';
import 'youtube_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of YoutubeLocalizations
/// returned by `YoutubeLocalizations.of(context)`.
///
/// Applications need to include `YoutubeLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'localization_file/youtube_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: YoutubeLocalizations.localizationsDelegates,
///   supportedLocales: YoutubeLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the YoutubeLocalizations.supportedLocales
/// property.
abstract class YoutubeLocalizations {
  YoutubeLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static YoutubeLocalizations? of(BuildContext context) {
    return Localizations.of<YoutubeLocalizations>(
      context,
      YoutubeLocalizations,
    );
  }

  static const LocalizationsDelegate<YoutubeLocalizations> delegate =
      _YoutubeLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// YouTube source name
  ///
  /// In zh, this message translates to:
  /// **'YouTube'**
  String get sourceName;

  /// Search sort option - relevance
  ///
  /// In zh, this message translates to:
  /// **'相关性'**
  String get sortRelevance;

  /// Search sort option - upload date
  ///
  /// In zh, this message translates to:
  /// **'上传时间'**
  String get sortUploadDate;

  /// Search sort option - view count
  ///
  /// In zh, this message translates to:
  /// **'播放量'**
  String get sortViewCount;

  /// Search sort option - rating
  ///
  /// In zh, this message translates to:
  /// **'评分'**
  String get sortRating;

  /// Upload date filter - last hour
  ///
  /// In zh, this message translates to:
  /// **'1小时内'**
  String get uploadDateLastHour;

  /// Upload date filter - today
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get uploadDateToday;

  /// Upload date filter - this week
  ///
  /// In zh, this message translates to:
  /// **'本周'**
  String get uploadDateThisWeek;

  /// Upload date filter - this month
  ///
  /// In zh, this message translates to:
  /// **'本月'**
  String get uploadDateThisMonth;

  /// Upload date filter - this year
  ///
  /// In zh, this message translates to:
  /// **'本年'**
  String get uploadDateThisYear;

  /// Duration filter - under 4 minutes
  ///
  /// In zh, this message translates to:
  /// **'4分钟以下'**
  String get durationUnder4Minutes;

  /// Duration filter - 4 to 20 minutes
  ///
  /// In zh, this message translates to:
  /// **'4-20分钟'**
  String get duration4To20Minutes;

  /// Duration filter - over 20 minutes
  ///
  /// In zh, this message translates to:
  /// **'20分钟以上'**
  String get durationOver20Minutes;

  /// Feature filter - live
  ///
  /// In zh, this message translates to:
  /// **'直播'**
  String get featureLive;

  /// Feature filter - 4K
  ///
  /// In zh, this message translates to:
  /// **'4K'**
  String get feature4K;

  /// Feature filter - HD
  ///
  /// In zh, this message translates to:
  /// **'高清'**
  String get featureHD;

  /// Feature filter - subtitles/CC
  ///
  /// In zh, this message translates to:
  /// **'字幕/CC'**
  String get featureSubtitles;

  /// Feature filter - Creative Commons
  ///
  /// In zh, this message translates to:
  /// **'知识共享'**
  String get featureCreativeCommons;

  /// Feature filter - 3D
  ///
  /// In zh, this message translates to:
  /// **'3D'**
  String get feature3D;

  /// Feature filter - 360 degrees
  ///
  /// In zh, this message translates to:
  /// **'360°'**
  String get feature360;

  /// Feature filter - HDR
  ///
  /// In zh, this message translates to:
  /// **'HDR'**
  String get featureHDR;

  /// Content type filter - video
  ///
  /// In zh, this message translates to:
  /// **'视频'**
  String get contentTypeVideo;

  /// Content type filter - channel
  ///
  /// In zh, this message translates to:
  /// **'频道'**
  String get contentTypeChannel;

  /// Content type filter - playlist
  ///
  /// In zh, this message translates to:
  /// **'播放列表'**
  String get contentTypePlaylist;

  /// Content type filter - movie
  ///
  /// In zh, this message translates to:
  /// **'电影'**
  String get contentTypeMovie;
}

class _YoutubeLocalizationsDelegate
    extends LocalizationsDelegate<YoutubeLocalizations> {
  const _YoutubeLocalizationsDelegate();

  @override
  Future<YoutubeLocalizations> load(Locale locale) {
    return SynchronousFuture<YoutubeLocalizations>(
      lookupYoutubeLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_YoutubeLocalizationsDelegate old) => false;
}

YoutubeLocalizations lookupYoutubeLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return YoutubeLocalizationsEn();
    case 'zh':
      return YoutubeLocalizationsZh();
  }

  throw FlutterError(
    'YoutubeLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
