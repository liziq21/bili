import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'bilibili_localizations_en.dart';
import 'bilibili_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of BilibiliLocalizations
/// returned by `BilibiliLocalizations.of(context)`.
///
/// Applications need to include `BilibiliLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'localization_file/bilibili_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: BilibiliLocalizations.localizationsDelegates,
///   supportedLocales: BilibiliLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the BilibiliLocalizations.supportedLocales
/// property.
abstract class BilibiliLocalizations {
  BilibiliLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static BilibiliLocalizations? of(BuildContext context) {
    return Localizations.of<BilibiliLocalizations>(
      context,
      BilibiliLocalizations,
    );
  }

  static const LocalizationsDelegate<BilibiliLocalizations> delegate =
      _BilibiliLocalizationsDelegate();

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

  /// Bilibili source name
  ///
  /// In zh, this message translates to:
  /// **'哔哩哔哩'**
  String get sourceName;

  /// Video duration filter - all
  ///
  /// In zh, this message translates to:
  /// **'不限'**
  String get videoDurationAll;

  /// Video duration filter - under 10 minutes
  ///
  /// In zh, this message translates to:
  /// **'10分钟以下'**
  String get videoDurationUnder10Min;

  /// Video duration filter - 10 to 30 minutes
  ///
  /// In zh, this message translates to:
  /// **'10-30分钟'**
  String get videoDuration10To30Min;

  /// Video duration filter - 30 to 60 minutes
  ///
  /// In zh, this message translates to:
  /// **'30-60分钟'**
  String get videoDuration30To60Min;

  /// Video duration filter - over 60 minutes
  ///
  /// In zh, this message translates to:
  /// **'60分钟以上'**
  String get videoDurationOver60Min;

  /// User type filter - all users
  ///
  /// In zh, this message translates to:
  /// **'全部用户'**
  String get userTypeAll;

  /// User type filter - UP host
  ///
  /// In zh, this message translates to:
  /// **'UP主'**
  String get userTypeUp;

  /// User type filter - normal user
  ///
  /// In zh, this message translates to:
  /// **'普通用户'**
  String get userTypeNormal;

  /// User type filter - verified user
  ///
  /// In zh, this message translates to:
  /// **'认证用户'**
  String get userTypeVerified;

  /// Article category - all
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get articleCategoryAll;

  /// Article category - animation
  ///
  /// In zh, this message translates to:
  /// **'动画'**
  String get articleCategoryAnimation;

  /// Article category - games
  ///
  /// In zh, this message translates to:
  /// **'游戏'**
  String get articleCategoryGames;

  /// Article category - movies and shows
  ///
  /// In zh, this message translates to:
  /// **'影视'**
  String get articleCategoryMovies;

  /// Article category - life
  ///
  /// In zh, this message translates to:
  /// **'生活'**
  String get articleCategoryLife;

  /// Article category - interests
  ///
  /// In zh, this message translates to:
  /// **'兴趣'**
  String get articleCategoryInterests;

  /// Article category - light novels
  ///
  /// In zh, this message translates to:
  /// **'轻小说'**
  String get articleCategoryLightNovels;

  /// Article category - technology
  ///
  /// In zh, this message translates to:
  /// **'科技'**
  String get articleCategoryTechnology;

  /// Photo category - all
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get photoCategoryAll;

  /// Photo category - artists
  ///
  /// In zh, this message translates to:
  /// **'画师'**
  String get photoCategoryArtists;

  /// Photo category - photography
  ///
  /// In zh, this message translates to:
  /// **'摄影'**
  String get photoCategoryPhotography;

  /// Search sort option - total rank / default
  ///
  /// In zh, this message translates to:
  /// **'综合排序'**
  String get sortTotalRank;

  /// Search sort option - attention
  ///
  /// In zh, this message translates to:
  /// **'最多关注'**
  String get sortAttention;

  /// Search sort option - click count
  ///
  /// In zh, this message translates to:
  /// **'最多点击'**
  String get sortClick;

  /// Search sort option - bullet comment count
  ///
  /// In zh, this message translates to:
  /// **'最多弹幕'**
  String get sortDm;

  /// Search sort option - publish date
  ///
  /// In zh, this message translates to:
  /// **'最新发布'**
  String get sortPubDate;

  /// Search sort option - scores / comments
  ///
  /// In zh, this message translates to:
  /// **'最多评论'**
  String get sortScores;

  /// Search sort option - stows / favorites
  ///
  /// In zh, this message translates to:
  /// **'最多收藏'**
  String get sortStow;

  /// Live search sort option - online popularity
  ///
  /// In zh, this message translates to:
  /// **'人气排序'**
  String get sortOnline;

  /// Live search sort option - live start time
  ///
  /// In zh, this message translates to:
  /// **'开播时间'**
  String get sortLiveTime;

  /// User search sort option - default
  ///
  /// In zh, this message translates to:
  /// **'默认排序'**
  String get sortDefault;

  /// User search sort option - fans descending
  ///
  /// In zh, this message translates to:
  /// **'粉丝数从高到低'**
  String get sortFansDesc;

  /// User search sort option - fans ascending
  ///
  /// In zh, this message translates to:
  /// **'粉丝数从低到高'**
  String get sortFansAsc;

  /// User search sort option - level descending
  ///
  /// In zh, this message translates to:
  /// **'等级从高到低'**
  String get sortLevelDesc;

  /// User search sort option - level ascending
  ///
  /// In zh, this message translates to:
  /// **'等级从低到高'**
  String get sortLevelAsc;
}

class _BilibiliLocalizationsDelegate
    extends LocalizationsDelegate<BilibiliLocalizations> {
  const _BilibiliLocalizationsDelegate();

  @override
  Future<BilibiliLocalizations> load(Locale locale) {
    return SynchronousFuture<BilibiliLocalizations>(
      lookupBilibiliLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_BilibiliLocalizationsDelegate old) => false;
}

BilibiliLocalizations lookupBilibiliLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return BilibiliLocalizationsEn();
    case 'zh':
      return BilibiliLocalizationsZh();
  }

  throw FlutterError(
    'BilibiliLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
