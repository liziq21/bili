import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'localization_file/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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

  /// Search result category - all results
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get searchResultTypeAll;

  /// Search result category - videos
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get searchResultTypeVideo;

  /// Search result category - channels
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get searchResultTypeChannel;

  /// Search result category - live rooms
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get searchResultTypeLive;

  /// Search result category - playlists
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get searchResultTypePlaylist;

  /// Home app bar - settings entry tooltip
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings index group - playback and appearance sections
  ///
  /// In en, this message translates to:
  /// **'Playback & appearance'**
  String get settingsGroupPlayback;

  /// Settings index group - library and notification sections
  ///
  /// In en, this message translates to:
  /// **'Library & notifications'**
  String get settingsGroupLibrary;

  /// Settings index group - discovery and channel sections
  ///
  /// In en, this message translates to:
  /// **'Discovery & channel'**
  String get settingsGroupDiscovery;

  /// Settings index group - miscellaneous sections
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get settingsGroupOther;

  /// Settings group and subpage title - player
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get settingsPlayer;

  /// Player setting - default video quality
  ///
  /// In en, this message translates to:
  /// **'Default video quality'**
  String get playerDefaultQuality;

  /// Subtitle for the default video quality setting
  ///
  /// In en, this message translates to:
  /// **'Preferred quality when opening the player'**
  String get playerDefaultQualitySubtitle;

  /// Player setting - default playback speed
  ///
  /// In en, this message translates to:
  /// **'Default playback speed'**
  String get playerDefaultSpeed;

  /// Subtitle for the default playback speed setting
  ///
  /// In en, this message translates to:
  /// **'Preferred playback speed when opening the player'**
  String get playerDefaultSpeedSubtitle;

  /// Heading for player gesture settings
  ///
  /// In en, this message translates to:
  /// **'Playback gestures'**
  String get playerGestures;

  /// Toggle for seeking with player gestures
  ///
  /// In en, this message translates to:
  /// **'Swipe and double-tap to seek'**
  String get playerGestureSeek;

  /// Subtitle for the player seek gesture toggle
  ///
  /// In en, this message translates to:
  /// **'Swipe or double-tap the video to change position'**
  String get playerGestureSeekSubtitle;

  /// Toggle for changing volume with vertical gestures
  ///
  /// In en, this message translates to:
  /// **'Swipe to adjust volume'**
  String get playerGestureVolume;

  /// Subtitle for the player volume gesture toggle
  ///
  /// In en, this message translates to:
  /// **'Swipe up and down on the right side of the video to adjust volume'**
  String get playerGestureVolumeSubtitle;

  /// Toggle for changing brightness with vertical gestures
  ///
  /// In en, this message translates to:
  /// **'Swipe to adjust brightness'**
  String get playerGestureBrightness;

  /// Subtitle for the player brightness gesture toggle
  ///
  /// In en, this message translates to:
  /// **'Swipe up and down on the left side of the video to adjust brightness'**
  String get playerGestureBrightnessSubtitle;

  /// Toggle for temporary long-press playback boost
  ///
  /// In en, this message translates to:
  /// **'Hold to temporarily speed up'**
  String get playerGestureBoost;

  /// Subtitle for the player boost gesture toggle
  ///
  /// In en, this message translates to:
  /// **'Hold the video to temporarily switch to 2x speed'**
  String get playerGestureBoostSubtitle;

  /// Player setting - default sleep timer duration
  ///
  /// In en, this message translates to:
  /// **'Default sleep timer'**
  String get playerSleepTimerDefault;

  /// Subtitle for the default sleep timer setting
  ///
  /// In en, this message translates to:
  /// **'Start a countdown automatically when opening the player; disabled means no automatic timer'**
  String get playerSleepTimerDefaultSubtitle;

  /// Value meaning that the default sleep timer is disabled
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get playerSleepTimerOff;

  /// Player setting - default sleep timer end action
  ///
  /// In en, this message translates to:
  /// **'When the sleep timer ends'**
  String get playerSleepTimerAction;

  /// Subtitle for the default sleep timer end action setting
  ///
  /// In en, this message translates to:
  /// **'Pause immediately, finish the current video, or close the player when the timer ends'**
  String get playerSleepTimerActionSubtitle;

  /// Automatic player quality selection
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get playerQualityAuto;

  /// Video quality height shown in player settings
  ///
  /// In en, this message translates to:
  /// **'{p1}P'**
  String playerQualityHeight(String p1);

  /// Settings group and subpage title - watch history
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get settingsHistory;

  /// Toggle for recording watched videos in local history
  ///
  /// In en, this message translates to:
  /// **'Save watch history'**
  String get historyRecording;

  /// Subtitle for the watch history recording toggle
  ///
  /// In en, this message translates to:
  /// **'Keep watched videos in the local history'**
  String get historyRecordingSubtitle;

  /// Toggle for restoring the last saved video position
  ///
  /// In en, this message translates to:
  /// **'Resume playback'**
  String get historyResumePlayback;

  /// Subtitle for the resume playback toggle
  ///
  /// In en, this message translates to:
  /// **'Continue videos from the last saved position'**
  String get historyResumePlaybackSubtitle;

  /// Settings group and subpage title - local library
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get settingsLibrary;

  /// Toggle for syncing remote bookmarks to local library
  ///
  /// In en, this message translates to:
  /// **'Sync bookmarks'**
  String get libraryBookmarkSync;

  /// Subtitle for bookmark sync toggle
  ///
  /// In en, this message translates to:
  /// **'Keep local bookmarks in sync with remote'**
  String get libraryBookmarkSyncSubtitle;

  /// Setting for how long to keep search history
  ///
  /// In en, this message translates to:
  /// **'Search history retention'**
  String get librarySearchHistoryRetention;

  /// Subtitle for search history retention setting
  ///
  /// In en, this message translates to:
  /// **'Delete searches older than the selected period'**
  String get librarySearchHistoryRetentionSubtitle;

  /// Retention option - 7 days
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get librarySearchHistoryRetention7Days;

  /// Retention option - 30 days
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get librarySearchHistoryRetention30Days;

  /// Retention option - 90 days
  ///
  /// In en, this message translates to:
  /// **'90 days'**
  String get librarySearchHistoryRetention90Days;

  /// Retention option - keep forever
  ///
  /// In en, this message translates to:
  /// **'Forever'**
  String get librarySearchHistoryRetentionForever;

  /// Settings - subtitle of the danmaku settings entry
  ///
  /// In en, this message translates to:
  /// **'Opacity, font size, duration and how many rows pinned at the top and bottom'**
  String get danmakuSettingsSubtitle;

  /// Settings - action that drops decoded images from memory
  ///
  /// In en, this message translates to:
  /// **'Clear image cache'**
  String get clearImageCache;

  /// Settings - subtitle explaining what clearing the image cache does
  ///
  /// In en, this message translates to:
  /// **'Frees decoded images held in memory; covers reload when shown again'**
  String get clearImageCacheSubtitle;

  /// SnackBar - confirmation that the image cache was cleared
  ///
  /// In en, this message translates to:
  /// **'Image cache cleared'**
  String get imageCacheCleared;

  /// Settings group and subpage title - advanced options
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get settingsAdvanced;

  /// Settings section - visual customization
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// Follow system theme
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get appearanceThemeSystem;

  /// Light theme
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appearanceThemeLight;

  /// Dark theme
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appearanceThemeDark;

  /// Appearance settings placeholder entry for theme
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get appearanceTheme;

  /// Subtitle for theme setting
  ///
  /// In en, this message translates to:
  /// **'Theme mode for the app'**
  String get appearanceThemeSubtitle;

  /// Font size setting label
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get appearanceFontSize;

  /// Subtitle for font size setting
  ///
  /// In en, this message translates to:
  /// **'Adjust text size across the app'**
  String get appearanceFontSizeSubtitle;

  /// Font size option: Small
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get appearanceFontSizeSmall;

  /// Font size option: Standard
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get appearanceFontSizeStandard;

  /// Font size option: Large
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get appearanceFontSizeLarge;

  /// Font size option: X-Large
  ///
  /// In en, this message translates to:
  /// **'X-Large'**
  String get appearanceFontSizeXLarge;

  /// Dialog button - cancel action
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dialogCancel;

  /// Action button - select all items
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get actionSelectAll;

  /// Action button - deselect all
  ///
  /// In en, this message translates to:
  /// **'Deselect'**
  String get actionDeselect;

  /// Selection count indicator
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectionSelected(int count);

  /// Sleep timer picker title
  ///
  /// In en, this message translates to:
  /// **'Sleep timer'**
  String get sleepTimerTitle;

  /// Sleep timer group heading for pausing as soon as the countdown ends
  ///
  /// In en, this message translates to:
  /// **'Pause now'**
  String get sleepTimerActionNowLabel;

  /// Sleep timer group heading for stopping after the current item finishes
  ///
  /// In en, this message translates to:
  /// **'After current video'**
  String get sleepTimerAfterCurrentTitle;

  /// Video info - action that copies the creator page link
  ///
  /// In en, this message translates to:
  /// **'Copy creator page link'**
  String get copyCreatorLink;

  /// Snackbar - content copied
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get trackCopiedToClipboard;

  /// Settings entry label and settings page title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Home recommendations section - empty state; {p1} is the source name
  ///
  /// In en, this message translates to:
  /// **'No recommendations available from {p1}'**
  String sourceNoRecommendations(String p1);

  /// Home - empty state when the selected source provides no home feed
  ///
  /// In en, this message translates to:
  /// **'This source doesn\'t provide a home feed'**
  String get sourceNoHomeFeed;

  /// Home feed section - error state; {p1} is the section title
  ///
  /// In en, this message translates to:
  /// **'Failed to load {p1}'**
  String sectionLoadFailed(String p1);

  /// Home feed - hint shown under a failed section
  ///
  /// In en, this message translates to:
  /// **'Check your network connection and try again'**
  String get checkNetworkRetry;

  /// Home feed section - empty state; {p1} is the section title
  ///
  /// In en, this message translates to:
  /// **'No content in {p1}'**
  String sectionEmpty(String p1);

  /// Generic retry action used by error states and player overlays
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Home app bar - tooltip of the source picker button
  ///
  /// In en, this message translates to:
  /// **'Switch source'**
  String get switchDataSource;

  /// Home app bar - tooltip of the source picker when a video source can be switched
  ///
  /// In en, this message translates to:
  /// **'Switch video and media source'**
  String get switchVideoMediaSource;

  /// Live card and search result - fallback name when the streamer is unknown
  ///
  /// In en, this message translates to:
  /// **'Unknown streamer'**
  String get unknownStreamer;

  /// Live card - line naming the streamer; {p1} is the streamer name
  ///
  /// In en, this message translates to:
  /// **'Streamer: {p1}'**
  String streamerLabel(String p1);

  /// Metadata separator between two short values; punctuation only
  ///
  /// In en, this message translates to:
  /// **', '**
  String get commaSeparator;

  /// Video feed - button that loads the next page
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get continueLoading;

  /// Feed and media library - end-of-list marker
  ///
  /// In en, this message translates to:
  /// **'No more items'**
  String get noMoreItems;

  /// Home app bar - search field placeholder
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchHint;

  /// Search suggestion - action that fills the query into the search box; {p1} is the suggestion
  ///
  /// In en, this message translates to:
  /// **'Put {p1} in the search box'**
  String putIntoSearchBox(String p1);

  /// List or detail page - error state of a failed first load
  ///
  /// In en, this message translates to:
  /// **'Failed to load. Try again later'**
  String get loadFailedRetryLater;

  /// Error state when Bilibili rate-limits or risk-controls the request
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait a moment and try again'**
  String get rateLimitedRetryLater;

  /// Retry button label while a rate-limit cooldown is counting down
  ///
  /// In en, this message translates to:
  /// **'Retry in {seconds}s'**
  String retryInSeconds(int seconds);

  /// Search results - error state with a retry action
  ///
  /// In en, this message translates to:
  /// **'Failed to load. Retry'**
  String get loadFailedRetry;

  /// Paginated list - footer shown when loading the next page failed
  ///
  /// In en, this message translates to:
  /// **'Failed to load more. Retry'**
  String get moreLoadFailedRetry;

  /// Search - empty state when the query returns no results
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get nothingFound;

  /// Creator space - app bar title
  ///
  /// In en, this message translates to:
  /// **'Creators'**
  String get creatorTab;

  /// Fallback text when a creator has no profile description
  ///
  /// In en, this message translates to:
  /// **'No description available'**
  String get spaceDescriptionUnavailable;

  /// Creator space and channel settings - tab label for videos
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get videoTab;

  /// Search - action that clears the recent query list
  ///
  /// In en, this message translates to:
  /// **'Clear recent search history'**
  String get clearRecentSearchHistory;

  /// Search - button that clears the recent search history
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Search - accessibility label of a recent query chip; {p1} is the query
  ///
  /// In en, this message translates to:
  /// **'Search \"{p1}\"'**
  String searchQueryLabel(String p1);

  /// Search - button that opens the filter sheet
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// Search filter sheet - button that clears the selected filters
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// Dialog - affirmative button label
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get confirm;

  /// Search filter sheet - label of the upload date range filter
  ///
  /// In en, this message translates to:
  /// **'Select date range'**
  String get selectDateRange;

  /// Bottom navigation entry and library page title
  ///
  /// In en, this message translates to:
  /// **'Local library'**
  String get localLibrary;

  /// Local library - history section title
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// Library tab and video action - favorites
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorite;

  /// Local library - playlists tab label
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get playlists;

  /// Creator subscribe button and library action
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get subscribe;

  /// Local library filter - option that disables the source filter
  ///
  /// In en, this message translates to:
  /// **'All sources'**
  String get allSources;

  /// Local library item - metadata naming the source; {p1} is the source name
  ///
  /// In en, this message translates to:
  /// **'Source: {p1}'**
  String sourceLabel(String p1);

  /// Local library - filter button label
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// Local library filter sheet - title for choosing a source
  ///
  /// In en, this message translates to:
  /// **'Select source'**
  String get selectSource;

  /// Dialog title that asks to confirm deleting a playlist
  ///
  /// In en, this message translates to:
  /// **'Delete playlist?'**
  String get deletePlaylistConfirm;

  /// Dialog body warning that local entries in the playlist are deleted too
  ///
  /// In en, this message translates to:
  /// **'Local entries in this list will also be deleted.'**
  String get deletePlaylistNote;

  /// Dialog and sheet - dismiss button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Destructive action label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Playlist picker - empty state when the source has no favorites to add
  ///
  /// In en, this message translates to:
  /// **'No favorites to add from this source'**
  String get noFavoritesFromSource;

  /// SnackBar - failure prefix; {p1} is the underlying error message
  ///
  /// In en, this message translates to:
  /// **'Operation failed: {p1}'**
  String operationFailed(String p1);

  /// Local library - loading state of the favorites list
  ///
  /// In en, this message translates to:
  /// **'Loading favorites'**
  String get loadingFavorites;

  /// Local library - error state of the favorites list
  ///
  /// In en, this message translates to:
  /// **'Failed to load favorites'**
  String get favoritesLoadFailed;

  /// Tooltip for exporting the bookmark list to the clipboard
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportFavorites;

  /// Snackbar shown when the bookmark list could not be copied
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get favoritesExportFailed;

  /// Local library - empty state of the favorites list
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get noFavoritesYet;

  /// Metadata separator between creator and date; punctuation only
  ///
  /// In en, this message translates to:
  /// **' · '**
  String get spacedDot;

  /// Local library favorite row - more-actions tooltip
  ///
  /// In en, this message translates to:
  /// **'Favorite actions'**
  String get favoriteActions;

  /// Local library - action that opens the creator page
  ///
  /// In en, this message translates to:
  /// **'Open creator'**
  String get openCreator;

  /// Video action and library - removes the item from favorites
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get unfavorite;

  /// Local library - loading state of the playlists list
  ///
  /// In en, this message translates to:
  /// **'Loading playlists'**
  String get loadingPlaylists;

  /// Playlist picker and library - error state of the playlists list
  ///
  /// In en, this message translates to:
  /// **'Failed to load playlists'**
  String get playlistLoadFailed;

  /// Playlist picker and library - empty state of the playlists list
  ///
  /// In en, this message translates to:
  /// **'No playlists yet'**
  String get noPlaylistsYet;

  /// Playlist picker - action that opens the create-playlist dialog
  ///
  /// In en, this message translates to:
  /// **'New playlist'**
  String get newPlaylist;

  /// Local library playlist row - more-actions tooltip
  ///
  /// In en, this message translates to:
  /// **'Playlist actions'**
  String get playlistActions;

  /// Local library - action that adds the item to favorites
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addFavorite;

  /// Local library - action that deletes a playlist
  ///
  /// In en, this message translates to:
  /// **'Delete playlist'**
  String get deletePlaylist;

  /// Local library playlist - error state of its entries
  ///
  /// In en, this message translates to:
  /// **'Failed to load items'**
  String get itemsLoadFailed;

  /// Local library playlist - empty state
  ///
  /// In en, this message translates to:
  /// **'The list is empty'**
  String get listEmpty;

  /// Local library playlist entry - more-actions tooltip
  ///
  /// In en, this message translates to:
  /// **'Item actions'**
  String get itemActions;

  /// Local library playlist - moves the entry up
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get moveUp;

  /// Local library playlist - moves the entry down
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get moveDown;

  /// Local library playlist - removes the video from the playlist
  ///
  /// In en, this message translates to:
  /// **'Remove this entry'**
  String get removeThisEntry;

  /// Menu item to rename a local playlist
  ///
  /// In en, this message translates to:
  /// **'Rename playlist'**
  String get renamePlaylist;

  /// Dialog title for renaming a playlist
  ///
  /// In en, this message translates to:
  /// **'Rename playlist'**
  String get renamePlaylistConfirm;

  /// Dialog title for batch-deleting selected items
  ///
  /// In en, this message translates to:
  /// **'Delete items in bulk'**
  String get batchDeleteConfirm;

  /// Dialog content for batch delete confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete the {count, plural, =1{selected item} other{{count} selected items}}? This can\'t be undone.'**
  String batchDeleteNote(int count);

  /// Button label to delete selected items in edit mode
  ///
  /// In en, this message translates to:
  /// **'Delete selected'**
  String get deleteSelected;

  /// Button to enter edit mode for playlist items
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editMode;

  /// Button to exit edit mode
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Search box placeholder for playlist items
  ///
  /// In en, this message translates to:
  /// **'Search items...'**
  String get itemsSearchHint;

  /// Local library - loading state of the subscriptions list
  ///
  /// In en, this message translates to:
  /// **'Loading subscriptions'**
  String get loadingSubscriptions;

  /// Local library - error state of the subscriptions list
  ///
  /// In en, this message translates to:
  /// **'Failed to load subscriptions'**
  String get subscriptionsLoadFailed;

  /// Local library - empty state of the subscriptions list
  ///
  /// In en, this message translates to:
  /// **'No subscriptions yet'**
  String get noSubscriptionsYet;

  /// Local library subscriptions - group name for entries without a group
  ///
  /// In en, this message translates to:
  /// **'Ungrouped'**
  String get ungrouped;

  /// Local library subscription row - more-actions tooltip
  ///
  /// In en, this message translates to:
  /// **'Subscription actions'**
  String get subscriptionActions;

  /// Local library subscription - opens the group editor
  ///
  /// In en, this message translates to:
  /// **'Set group'**
  String get setGroup;

  /// Creator subscribe button and library action
  ///
  /// In en, this message translates to:
  /// **'Unsubscribe'**
  String get unsubscribe;

  /// Generic add action
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Local library item - metadata label for the data source
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// Create playlist dialog - name field label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Create playlist dialog - submit button
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Group editor dialog - field label
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get groupName;

  /// Group editor dialog - hint that an empty name means ungrouped
  ///
  /// In en, this message translates to:
  /// **'Leave empty for ungrouped'**
  String get groupNameHint;

  /// Dialog and sheet - save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Bottom navigation - personal library entry
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get mine;

  /// Media library - watch history page title
  ///
  /// In en, this message translates to:
  /// **'Watch history'**
  String get watchHistory;

  /// Watch history header - how many entries are loaded; {p1} is the count
  ///
  /// In en, this message translates to:
  /// **'Watch history · {p1} loaded'**
  String watchHistoryLoadedCount(String p1);

  /// Media library tab - error state; {p1} is the tab name
  ///
  /// In en, this message translates to:
  /// **'{p1} · Failed to load'**
  String tabLoadFailed(String p1);

  /// Media library - loads the next page of history
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// Media library - header tooltip while the watch history is loading
  ///
  /// In en, this message translates to:
  /// **'Loading history...'**
  String get loadingHistory;

  /// Media library - header tooltip that loads the next page of watch history
  ///
  /// In en, this message translates to:
  /// **'Load more history'**
  String get loadMoreHistory;

  /// Media library - error state of the watch history list
  ///
  /// In en, this message translates to:
  /// **'Failed to load history'**
  String get historyLoadFailed;

  /// Media library - empty state of the watch history list
  ///
  /// In en, this message translates to:
  /// **'No watch history yet'**
  String get noWatchHistory;

  /// Watch history entry - total duration; {p1} is a formatted duration
  ///
  /// In en, this message translates to:
  /// **'Duration {p1}'**
  String durationLabel(String p1);

  /// Watch history entry - when the video was watched; {p1} is a relative time
  ///
  /// In en, this message translates to:
  /// **'Watched {p1}'**
  String watchedAt(String p1);

  /// Watch history entry - badge for a video watched to the end
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get finishedWatching;

  /// Watch history entry - watched progress; {p1} is a formatted duration
  ///
  /// In en, this message translates to:
  /// **'Watched {p1}'**
  String watchedDuration(String p1);

  /// Relative time - within the last minute
  ///
  /// In en, this message translates to:
  /// **'Just Now'**
  String get justNow;

  /// Relative time - minutes ago; {p1} is the number of minutes
  ///
  /// In en, this message translates to:
  /// **'{p1, plural, =1{1 minute ago} other{{p1} minutes ago}}'**
  String minutesAgo(int p1);

  /// Relative time - hours ago; {p1} is the number of hours
  ///
  /// In en, this message translates to:
  /// **'{p1, plural, =1{1 hour ago} other{{p1} hours ago}}'**
  String hoursAgo(int p1);

  /// Relative time - days ago; {p1} is the number of days
  ///
  /// In en, this message translates to:
  /// **'{p1, plural, =1{1 day ago} other{{p1} days ago}}'**
  String daysAgo(int p1);

  /// Playlist picker sheet - title
  ///
  /// In en, this message translates to:
  /// **'Add to Playlist'**
  String get addToPlaylistTitle;

  /// Playlist picker - adds the video to the named playlist; {p1} is the playlist name
  ///
  /// In en, this message translates to:
  /// **'Add to {p1}'**
  String addToNamedPlaylist(String p1);

  /// Playlist picker - accessibility label of the same action; {p1} is the playlist name
  ///
  /// In en, this message translates to:
  /// **'Add to playlist {p1}'**
  String addToNamedPlaylistLong(String p1);

  /// SnackBar - adding to a playlist failed; {p1} is the error message
  ///
  /// In en, this message translates to:
  /// **'Failed to add: {p1}'**
  String addFailed(String p1);

  /// SnackBar - creating the playlist or adding failed; {p1} is the error message
  ///
  /// In en, this message translates to:
  /// **'Failed to create or add: {p1}'**
  String createOrAddFailed(String p1);

  /// Create playlist dialog - validation error for an empty name
  ///
  /// In en, this message translates to:
  /// **'Enter a playlist name'**
  String get playlistNameRequired;

  /// Video screen - tab label for the info and related section
  ///
  /// In en, this message translates to:
  /// **'Info & related'**
  String get infoAndRelated;

  /// Video screen - comments tab label; the count in the copy is a fixed sample, not data-driven
  ///
  /// In en, this message translates to:
  /// **'Comments (1,429)'**
  String get commentsCountTab;

  /// Danmaku settings screen and section title
  ///
  /// In en, this message translates to:
  /// **'Danmaku settings'**
  String get danmakuSettingsTitle;

  /// Danmaku settings - switch that renders danmaku
  ///
  /// In en, this message translates to:
  /// **'Show danmaku'**
  String get showDanmaku;

  /// Danmaku settings - switch that draws timeline danmaku over the video
  ///
  /// In en, this message translates to:
  /// **'Show timeline danmaku over the video'**
  String get showTimelineDanmakuOnVideo;

  /// Danmaku settings - how long a scrolling comment stays on screen
  ///
  /// In en, this message translates to:
  /// **'Regular danmaku duration'**
  String get regularDanmakuDuration;

  /// Duration picker - value in seconds; {p1} is the number of seconds
  ///
  /// In en, this message translates to:
  /// **'{p1} s'**
  String secondsValue(String p1);

  /// Danmaku settings - opacity slider label
  ///
  /// In en, this message translates to:
  /// **'Opacity'**
  String get opacity;

  /// Danmaku settings - font size slider label
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get fontSize;

  /// Danmaku settings - text stroke slider label
  ///
  /// In en, this message translates to:
  /// **'Stroke radius'**
  String get strokeRadius;

  /// Player - playback speed chip label
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get playbackSpeed;

  /// Quality picker - lets the player choose the bitrate
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get auto;

  /// Player and live - quality picker title
  ///
  /// In en, this message translates to:
  /// **'Select quality'**
  String get qualitySelect;

  /// Quality picker - message when the source exposes a single quality
  ///
  /// In en, this message translates to:
  /// **'This source offers only one quality'**
  String get singleQualityOnly;

  /// Sleep timer - stops playback when the current video ends
  ///
  /// In en, this message translates to:
  /// **'After current'**
  String get afterCurrentItem;

  /// Player - sleep timer chip label
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get timer;

  /// Sleep timer and player settings - value in minutes; {p1} is the number of minutes
  ///
  /// In en, this message translates to:
  /// **'{p1} min'**
  String minutesValue(String p1);

  /// Sleep timer - cancels the running timer
  ///
  /// In en, this message translates to:
  /// **'Cancel timer'**
  String get cancelTimer;

  /// Sleep timer option for entering a custom duration
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get sleepTimerCustom;

  /// Dialog title for entering a custom sleep timer duration
  ///
  /// In en, this message translates to:
  /// **'Custom sleep timer'**
  String get sleepTimerCustomTitle;

  /// Selected custom sleep timer duration
  ///
  /// In en, this message translates to:
  /// **'{p1} min'**
  String sleepTimerCustomValue(String p1);

  /// Input hint for a custom sleep timer duration
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get sleepTimerMinutesHint;

  /// Validation error for a custom sleep timer duration
  ///
  /// In en, this message translates to:
  /// **'Enter a duration from 1 to 1440 minutes.'**
  String get sleepTimerInvalidDuration;

  /// Compact count unit for values >= 10,000. Kept as the Chinese 万 unit because call sites divide by 10,000 before formatting; an English K/M unit would need a different divisor (tracked separately).
  ///
  /// In en, this message translates to:
  /// **'{p1}万'**
  String countCompactWan(String p1);

  /// Comments section - empty state when the source cannot return comments
  ///
  /// In en, this message translates to:
  /// **'This source doesn\'t support comments'**
  String get commentsUnsupportedSource;

  /// Comments section - error state
  ///
  /// In en, this message translates to:
  /// **'Failed to load comments. Try again later'**
  String get commentsLoadFailed;

  /// Comments section - empty state
  ///
  /// In en, this message translates to:
  /// **'No comments yet'**
  String get noComments;

  /// Comment row - like action carrying the like count; {p1} is the count
  ///
  /// In en, this message translates to:
  /// **'Like comment {p1}'**
  String likeCommentCount(String p1);

  /// Comment row - removes the like
  ///
  /// In en, this message translates to:
  /// **'Unlike comment'**
  String get unlikeComment;

  /// Comment row - likes the comment
  ///
  /// In en, this message translates to:
  /// **'Like comment'**
  String get likeComment;

  /// Comment thread - hides the replies
  ///
  /// In en, this message translates to:
  /// **'Collapse replies'**
  String get collapseReplies;

  /// Comment thread - expands the replies; {p1} is the reply count
  ///
  /// In en, this message translates to:
  /// **'View {p1} replies'**
  String viewReplyCount(String p1);

  /// Comment thread - message when replies cannot be loaded
  ///
  /// In en, this message translates to:
  /// **'Replies aren\'t available yet'**
  String get repliesUnavailable;

  /// Player - error text when the stream fails to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load video. Try again'**
  String get videoLoadFailed;

  /// Video info - empty state for related videos
  ///
  /// In en, this message translates to:
  /// **'No related recommendations'**
  String get noRecommendations;

  /// Video info - view count metadata; {p1} is a formatted count
  ///
  /// In en, this message translates to:
  /// **'{p1} views'**
  String viewCountLabel(String p1);

  /// Metadata separator between view count and date; punctuation only
  ///
  /// In en, this message translates to:
  /// **'·'**
  String get dotSeparator;

  /// Video info - danmaku (bullet comment) count; {p1} is a formatted count
  ///
  /// In en, this message translates to:
  /// **'{p1} danmaku'**
  String danmakuCountLabel(String p1);

  /// Video info - copyright tag for a self-made (original) upload
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get copyrightOriginal;

  /// Video info - copyright tag for a reposted upload
  ///
  /// In en, this message translates to:
  /// **'Reposted'**
  String get copyrightRepost;

  /// Video info - accessibility label that unfollows the creator
  ///
  /// In en, this message translates to:
  /// **'Unfollow creator'**
  String get unfollowCreator;

  /// Video info - accessibility label that follows the creator
  ///
  /// In en, this message translates to:
  /// **'Follow creator'**
  String get followCreator;

  /// Video info - follow button accessibility label with the creator name; {p1} is the name
  ///
  /// In en, this message translates to:
  /// **'Following creator {p1}'**
  String followingCreatorNamed(String p1);

  /// Video info - follow button accessibility label with the creator name; {p1} is the name
  ///
  /// In en, this message translates to:
  /// **'Follow creator {p1}'**
  String followCreatorNamed(String p1);

  /// Video info - follow button state when already following
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get following;

  /// Video info - follow button state when not following
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get follow;

  /// Video info - like action
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like;

  /// Video info - short label of the add-to-playlist button
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get list;

  /// Video info - action name of the add-to-playlist button, used in its accessibility label
  ///
  /// In en, this message translates to:
  /// **'Add to playlist'**
  String get addToPlaylist;

  /// Video info - tooltip of the add-to-playlist button
  ///
  /// In en, this message translates to:
  /// **'Add to local playlist'**
  String get addToLocalPlaylist;

  /// Video info - label of the switch-source action button
  ///
  /// In en, this message translates to:
  /// **'Switch source'**
  String get switchSource;

  /// Video info - tooltip of the switch-source action button
  ///
  /// In en, this message translates to:
  /// **'Switch video source'**
  String get switchVideoSource;

  /// Video info - snackbar shown when the switch-source action is tapped
  ///
  /// In en, this message translates to:
  /// **'Automatically switch to the best available route'**
  String get autoSwitchBestRoute;

  /// Video info - action name of the share button
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Video info - tooltip of the share button
  ///
  /// In en, this message translates to:
  /// **'Share video'**
  String get shareVideo;

  /// Video info - snackbar shown when the share action is tapped
  ///
  /// In en, this message translates to:
  /// **'Share multi-source video link'**
  String get shareMultiSourceLink;

  /// Video info - danmaku switch label when danmaku are on
  ///
  /// In en, this message translates to:
  /// **'Danmaku on'**
  String get danmakuStateOn;

  /// Video info - danmaku switch label when danmaku are off
  ///
  /// In en, this message translates to:
  /// **'Danmaku off'**
  String get danmakuStateOff;

  /// Video info - danmaku switch label
  ///
  /// In en, this message translates to:
  /// **'Danmaku'**
  String get danmaku;

  /// Video info - accessibility label that turns danmaku off
  ///
  /// In en, this message translates to:
  /// **'Turn danmaku off'**
  String get danmakuActionOff;

  /// Video info - accessibility label that turns danmaku on
  ///
  /// In en, this message translates to:
  /// **'Turn danmaku on'**
  String get danmakuActionOn;

  /// Video info - summary section title
  ///
  /// In en, this message translates to:
  /// **'Summary & key takeaways'**
  String get synopsisSectionTitle;

  /// Video info - hides the summary
  ///
  /// In en, this message translates to:
  /// **'Collapse summary'**
  String get collapseSynopsis;

  /// Video info - shows the full summary
  ///
  /// In en, this message translates to:
  /// **'Expand full outline'**
  String get expandSynopsis;

  /// Generic collapse action
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapse;

  /// Demo summary text shown when the source provides none
  ///
  /// In en, this message translates to:
  /// **'An in-depth look at why Flutter moved from Skia to Impeller for rendering. Covers shader precompilation, RenderPass reuse, direct Metal / Vulkan backend binding, and techniques for eliminating frame drops on mobile.'**
  String get sampleSynopsisFallback;

  /// Video info - chapters section title
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get chapters;

  /// Video info - related videos section title
  ///
  /// In en, this message translates to:
  /// **'Multi-source recommendations'**
  String get multiSourceRecommendations;

  /// Video info - transient label while the video is added to the queue
  ///
  /// In en, this message translates to:
  /// **'Adding to queue'**
  String get addingToQueue;

  /// Video info - adds the video to the play queue
  ///
  /// In en, this message translates to:
  /// **'Add to play queue'**
  String get addToPlayQueue;

  /// Video info - confirmation after adding to the queue
  ///
  /// In en, this message translates to:
  /// **'Added to play queue'**
  String get addedToPlayQueue;

  /// Video info - adding to the queue failed
  ///
  /// In en, this message translates to:
  /// **'Failed to add to queue'**
  String get addToQueueFailed;

  /// Video info - tooltip of an active action button that cancels it; {p1} is the action name
  ///
  /// In en, this message translates to:
  /// **'Cancel {p1}'**
  String cancelAction(String p1);

  /// Player - plays the previous queue item
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previousItem;

  /// Player - plays the next queue item
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextItem;

  /// Player and queue sheet - loop mode off
  ///
  /// In en, this message translates to:
  /// **'Loop: off'**
  String get loopOff;

  /// Player and queue sheet - repeat the current item
  ///
  /// In en, this message translates to:
  /// **'Repeat one'**
  String get loopOne;

  /// Player and queue sheet - repeat the whole queue
  ///
  /// In en, this message translates to:
  /// **'Repeat queue'**
  String get loopQueue;

  /// Player - shrinks the player
  ///
  /// In en, this message translates to:
  /// **'Minimize'**
  String get minimize;

  /// Playback error category - network failure
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get playbackErrorNetwork;

  /// Playback error category - the stream could not be opened
  ///
  /// In en, this message translates to:
  /// **'Stream failed to open'**
  String get playbackErrorOpen;

  /// Playback error category - media decoding failure
  ///
  /// In en, this message translates to:
  /// **'Decoder error'**
  String get playbackErrorDecoder;

  /// Playback error category - DRM failure
  ///
  /// In en, this message translates to:
  /// **'DRM error'**
  String get playbackErrorDrm;

  /// Playback error category - authorization failure
  ///
  /// In en, this message translates to:
  /// **'Authorization error'**
  String get playbackErrorAuthorization;

  /// Playback error category - unknown failure
  ///
  /// In en, this message translates to:
  /// **'Unknown playback error'**
  String get playbackErrorUnknown;

  /// Playback status shown while retrying a network failure
  ///
  /// In en, this message translates to:
  /// **'Retrying...'**
  String get playbackRetrying;

  /// Player error action - skip the current queue item
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// App bar and player - navigate back
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Player - enters fullscreen
  ///
  /// In en, this message translates to:
  /// **'Fullscreen'**
  String get fullscreen;

  /// Player placeholder - 1080P high bitrate quality badge
  ///
  /// In en, this message translates to:
  /// **'1080P high bitrate'**
  String get highBitrate1080;

  /// Player - pause playback
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// Player - start playback
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// Live player - toggles fullscreen
  ///
  /// In en, this message translates to:
  /// **'Toggle fullscreen'**
  String get fullscreenToggle;

  /// Not-found screen - no usable data source
  ///
  /// In en, this message translates to:
  /// **'Source unavailable'**
  String get sourceUnavailable;

  /// Compact count unit for values >= 100,000,000. Kept as the Chinese 亿 unit because call sites divide by 100,000,000 before formatting; an English K/M unit would need a different divisor (tracked separately).
  ///
  /// In en, this message translates to:
  /// **'{p1}亿'**
  String countCompactYi(String p1);

  /// Relative time - years ago; {p1} is the number of years
  ///
  /// In en, this message translates to:
  /// **'{p1, plural, =1{1 year ago} other{{p1} years ago}}'**
  String yearsAgoCompact(int p1);

  /// Relative time - months ago; {p1} is the number of months
  ///
  /// In en, this message translates to:
  /// **'{p1, plural, =1{1 month ago} other{{p1} months ago}}'**
  String monthsAgoCompact(int p1);

  /// Video card - view count and relative date; {p1} is the count, {p2} is the date
  ///
  /// In en, this message translates to:
  /// **'{p1} views • {p2}'**
  String viewsWithDate(String p1, String p2);

  /// Video card - view count; {p1} is a formatted count
  ///
  /// In en, this message translates to:
  /// **'{p1} views'**
  String viewsCount(String p1);

  /// Metadata separator between two short values; punctuation only
  ///
  /// In en, this message translates to:
  /// **' • '**
  String get spacedBullet;

  /// Video card and list row - creator line; {p1} is the creator name
  ///
  /// In en, this message translates to:
  /// **'Creator: {p1}'**
  String creatorLabel(String p1);

  /// Video card - duration metadata; {p1} is a formatted duration
  ///
  /// In en, this message translates to:
  /// **'Duration {p1}'**
  String durationPrefix(String p1);

  /// Video card - fallback name when the creator is unknown
  ///
  /// In en, this message translates to:
  /// **'Unknown creator'**
  String get unknownCreator;

  /// Video card - creator name and subtitle; {p1} is the creator, {p2} is the view count and/or date
  ///
  /// In en, this message translates to:
  /// **'{p1} • {p2}'**
  String creatorWithSubtitle(String p1, String p2);

  /// Card and row - more-actions tooltip
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// Creator row - follower count; {p1} is a formatted count
  ///
  /// In en, this message translates to:
  /// **'{p1} followers'**
  String subscribersCount(String p1);

  /// Creator row - video count; {p1} is a formatted count
  ///
  /// In en, this message translates to:
  /// **'{p1} videos'**
  String videosCount(String p1);

  /// Live card - badge for a running stream
  ///
  /// In en, this message translates to:
  /// **'Live now'**
  String get liveNow;

  /// Bottom navigation - home entry
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHomeLabel;

  /// Bottom navigation and search entry label
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Live route - the live room's source is unavailable
  ///
  /// In en, this message translates to:
  /// **'The live stream\'s source is unavailable'**
  String get liveSourceUnavailable;

  /// Creator route - the creator's source is unavailable
  ///
  /// In en, this message translates to:
  /// **'The creator\'s source is unavailable'**
  String get creatorSourceUnavailable;

  /// Video route - the video's source is unavailable
  ///
  /// In en, this message translates to:
  /// **'The video\'s source is unavailable'**
  String get videoSourceUnavailable;

  /// Video detail - empty state when the source cannot return details
  ///
  /// In en, this message translates to:
  /// **'This source doesn\'t support video details yet'**
  String get videoDetailSourceUnsupported;

  /// Video player placeholder slider progress label
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// Player placeholder - switch action label
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get switchAction;

  /// Title and tooltip for the playback queue
  ///
  /// In en, this message translates to:
  /// **'Playback queue'**
  String get playbackQueue;

  /// Number of items shown in the playback queue
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String playbackQueueCount(int count);

  /// Fallback title for a queue item without video metadata
  ///
  /// In en, this message translates to:
  /// **'Video {count}'**
  String queueItemFallback(int count);

  /// Empty state for the playback queue
  ///
  /// In en, this message translates to:
  /// **'Your playback queue is empty'**
  String get queueEmpty;

  /// Tooltip for removing an item from the playback queue
  ///
  /// In en, this message translates to:
  /// **'Remove from queue'**
  String get removeFromQueue;

  /// Accessibility label for the current playback queue item
  ///
  /// In en, this message translates to:
  /// **'Currently playing'**
  String get currentlyPlaying;

  /// Button that starts a local playlist from its first item
  ///
  /// In en, this message translates to:
  /// **'Play all'**
  String get playPlaylist;

  /// Error shown when no playlist entry could be resolved to a playable stream
  ///
  /// In en, this message translates to:
  /// **'Could not start this playlist'**
  String get playlistPlaybackFailed;

  /// Settings group and subpage title - home configuration
  ///
  /// In en, this message translates to:
  /// **'Discovery'**
  String get settingsDiscovery;

  /// Settings group and subpage title - channel page tabs
  ///
  /// In en, this message translates to:
  /// **'Channel'**
  String get settingsChannel;

  /// Snack bar shown when a settings toggle cannot be persisted
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the setting'**
  String get settingsSaveFailed;

  /// Home configuration editor page title
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeConfigTitle;

  /// Home configuration section label - feed tabs
  ///
  /// In en, this message translates to:
  /// **'Tabs'**
  String get homeConfigTabs;

  /// Home configuration action - move a tab up
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get homeConfigMoveUp;

  /// Home configuration action - move a tab down
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get homeConfigMoveDown;

  /// Home configuration action - set a tab as the main tab
  ///
  /// In en, this message translates to:
  /// **'Set as main'**
  String get homeConfigSetMain;

  /// Home configuration setting - grid columns per orientation
  ///
  /// In en, this message translates to:
  /// **'Grid columns'**
  String get homeConfigGridColumns;

  /// Home configuration orientation label - portrait
  ///
  /// In en, this message translates to:
  /// **'Portrait'**
  String get homeConfigPortrait;

  /// Home configuration orientation label - landscape
  ///
  /// In en, this message translates to:
  /// **'Landscape'**
  String get homeConfigLandscape;

  /// Home configuration tab visibility state - visible
  ///
  /// In en, this message translates to:
  /// **'Visible'**
  String get homeConfigVisible;

  /// Home configuration tab visibility state - hidden
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get homeConfigHidden;

  /// LIZ-84 live room detail and stream
  ///
  /// In en, this message translates to:
  /// **'Loading live room'**
  String get liveRoomLoading;

  /// Live room screen app bar title
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get liveScreenTitle;

  /// LIZ-84 live room detail and stream
  ///
  /// In en, this message translates to:
  /// **'Failed to load live room'**
  String get liveRoomError;

  /// LIZ-84 live room detail and stream
  ///
  /// In en, this message translates to:
  /// **'Failed to load live stream'**
  String get liveStreamError;

  /// LIZ-84 live room detail and stream
  ///
  /// In en, this message translates to:
  /// **'watching'**
  String get liveViewers;

  /// LIZ-113 live room badge when the anchor is no longer live
  ///
  /// In en, this message translates to:
  /// **'Stream ended'**
  String get liveRoomEnded;

  /// Header for recent search history list
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get recentSearches;

  /// Button to clear all search history
  ///
  /// In en, this message translates to:
  /// **'Clear all search history'**
  String get clearAllSearchHistory;

  /// Tooltip and button label for clearing the whole local watch history
  ///
  /// In en, this message translates to:
  /// **'Clear all watch history'**
  String get clearAllWatchHistory;

  /// Dialog title for confirming clearing the whole watch history
  ///
  /// In en, this message translates to:
  /// **'Clear all watch history?'**
  String get clearWatchHistoryConfirm;

  /// Dialog message for confirming clearing the whole watch history
  ///
  /// In en, this message translates to:
  /// **'This removes every entry from your watch history. The action cannot be undone.'**
  String get clearWatchHistoryMessage;

  /// Snack bar shown after a single history entry is deleted
  ///
  /// In en, this message translates to:
  /// **'Removed from history'**
  String get historyItemRemoved;

  /// Snack bar shown after the whole watch history is cleared
  ///
  /// In en, this message translates to:
  /// **'Watch history cleared'**
  String get watchHistoryCleared;

  /// Empty state when there is no search history
  ///
  /// In en, this message translates to:
  /// **'No search history yet'**
  String get noSearchHistory;

  /// Dialog title for confirming deletion of a single history item
  ///
  /// In en, this message translates to:
  /// **'Delete \"{p1}\" from history?'**
  String deleteHistoryItemConfirm(String p1);

  /// LIZ-77 remote playlist detail page title
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get playlistTitle;

  /// LIZ-77 shown when no media source can resolve the playlist route
  ///
  /// In en, this message translates to:
  /// **'The source of this playlist is unavailable'**
  String get playlistSourceUnavailable;

  /// LIZ-77 empty state for a playlist without videos
  ///
  /// In en, this message translates to:
  /// **'This playlist has no videos yet'**
  String get playlistEmpty;

  /// LIZ-77 placeholder when the playlist has no description
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get playlistDescriptionUnavailable;

  /// LIZ-77 number of videos advertised by the playlist
  ///
  /// In en, this message translates to:
  /// **'{count} videos'**
  String playlistItemCount(String count);

  /// LIZ-77 button that fetches every page of the playlist
  ///
  /// In en, this message translates to:
  /// **'Fetch all'**
  String get playlistFetchAll;

  /// LIZ-77 progress shown while fetching all playlist pages
  ///
  /// In en, this message translates to:
  /// **'Fetched {count}'**
  String playlistFetchAllProgress(String count);

  /// LIZ-77 progress shown after every playlist page was fetched
  ///
  /// In en, this message translates to:
  /// **'Fetched all {count} videos'**
  String playlistFetchAllDone(String count);

  /// LIZ-77 progress shown when fetching all pages was interrupted
  ///
  /// In en, this message translates to:
  /// **'Fetched {count} videos before the fetch stopped'**
  String playlistFetchAllPartial(String count);

  /// Settings group and subpage title - notifications
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// Toggle for feed update notifications
  ///
  /// In en, this message translates to:
  /// **'Feed update notifications'**
  String get feedUpdateNotifications;

  /// Subtitle for feed update notifications toggle
  ///
  /// In en, this message translates to:
  /// **'Notify when new feed items are detected'**
  String get feedUpdateNotificationsSubtitle;

  /// Setting for minimum new items to trigger notification
  ///
  /// In en, this message translates to:
  /// **'Notification threshold'**
  String get feedUpdateThreshold;

  /// Subtitle for notification threshold setting
  ///
  /// In en, this message translates to:
  /// **'Only notify when new items reach this count'**
  String get feedUpdateThresholdSubtitle;

  /// Threshold option with count
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String feedUpdateThresholdOption(int count);

  /// Threshold option to disable notifications
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get feedUpdateThresholdOff;

  /// App bar title and bottom navigation label for the subscription feed
  ///
  /// In en, this message translates to:
  /// **'Subscription feed'**
  String get feedTitle;

  /// Unread entry count badge of a channel group
  ///
  /// In en, this message translates to:
  /// **'{count} unread'**
  String feedUnreadCount(int count);

  /// Action that marks every entry of a channel as read
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get feedMarkAllRead;

  /// Tooltip that expands a collapsed channel group
  ///
  /// In en, this message translates to:
  /// **'Expand {channel}'**
  String feedExpandChannel(String channel);

  /// Tooltip that collapses an expanded channel group
  ///
  /// In en, this message translates to:
  /// **'Collapse {channel}'**
  String feedCollapseChannel(String channel);

  /// Empty state title of the subscription feed
  ///
  /// In en, this message translates to:
  /// **'No subscription updates yet'**
  String get feedEmptyTitle;

  /// Empty state description of the subscription feed
  ///
  /// In en, this message translates to:
  /// **'New posts from channels you follow will appear here'**
  String get feedEmptyDescription;

  /// Shown when the data source cannot fetch channel uploads
  ///
  /// In en, this message translates to:
  /// **'This source has no subscription feed'**
  String get feedUnsupportedTitle;

  /// Title of the system notification shown when the subscription feed grows past the threshold
  ///
  /// In en, this message translates to:
  /// **'New feed items'**
  String get feedUpdateNotificationTitle;

  /// Body of the feed update notification; {count} is the number of new unread entries
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new item in your feed} other{{count} new items in your feed}}'**
  String feedUpdateNotificationBody(int count);

  /// Shown on a creator page when the source cannot list channel videos
  ///
  /// In en, this message translates to:
  /// **'This source has no channel videos'**
  String get channelVideosUnsupported;

  /// Shown on a creator page when the channel has no uploaded videos
  ///
  /// In en, this message translates to:
  /// **'No videos yet'**
  String get channelVideosEmpty;

  /// Creator-page tab that lists the channel's playlists (seasons)
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get channelTabPlaylists;

  /// Shown on a creator page when the channel has no playlists
  ///
  /// In en, this message translates to:
  /// **'No playlists yet'**
  String get channelPlaylistsEmpty;

  /// Sleep timer action that pauses playback and closes the player when the countdown ends
  ///
  /// In en, this message translates to:
  /// **'Close player'**
  String get sleepTimerActionExitPlayerLabel;

  /// Sleep timer picker section heading for the duration list
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get sleepTimerDuration;

  /// Title of the system notification shown one minute before the sleep timer stops playback
  ///
  /// In en, this message translates to:
  /// **'Sleep timer'**
  String get sleepTimerEndingSoonTitle;

  /// Body of the system notification shown one minute before the sleep timer stops playback
  ///
  /// In en, this message translates to:
  /// **'Playback stops in 1 minute'**
  String get sleepTimerEndingSoonBody;

  /// Android notification channel name for the sleep timer, shown in system settings
  ///
  /// In en, this message translates to:
  /// **'Sleep timer'**
  String get sleepTimerChannelName;

  /// Android notification channel description for the sleep timer, shown in system settings
  ///
  /// In en, this message translates to:
  /// **'Warns one minute before playback stops'**
  String get sleepTimerChannelDescription;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
