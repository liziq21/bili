import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

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
  static const List<Locale> supportedLocales = <Locale>[Locale('zh')];

  /// App name - DO NOT TRANSLATE
  ///
  /// In zh, this message translates to:
  /// **'pili'**
  String get appName;

  /// Bottom navigation - Home tab
  ///
  /// In zh, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom navigation - Library tab
  ///
  /// In zh, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// Bottom navigation - Settings tab
  ///
  /// In zh, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Bottom navigation - Extension store tab
  ///
  /// In zh, this message translates to:
  /// **'Repo'**
  String get navStore;

  /// Home screen title
  ///
  /// In zh, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// Subtitle shown below search box
  ///
  /// In zh, this message translates to:
  /// **'Paste a supported URL or search by name'**
  String get homeSubtitle;

  /// Info text about supported URL types
  ///
  /// In zh, this message translates to:
  /// **'Supports: Track, Album, Playlist, Artist URLs'**
  String get homeSupports;

  /// Section header for recent searches
  ///
  /// In zh, this message translates to:
  /// **'Recent'**
  String get homeRecent;

  /// Filter chip - show all items
  ///
  /// In zh, this message translates to:
  /// **'All'**
  String get historyFilterAll;

  /// Filter chip - show albums only
  ///
  /// In zh, this message translates to:
  /// **'Albums'**
  String get historyFilterAlbums;

  /// Filter chip - show singles only
  ///
  /// In zh, this message translates to:
  /// **'Singles'**
  String get historyFilterSingles;

  /// Search bar placeholder in history
  ///
  /// In zh, this message translates to:
  /// **'Search history...'**
  String get historySearchHint;

  /// Settings screen title
  ///
  /// In zh, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings section - download options
  ///
  /// In zh, this message translates to:
  /// **'Download'**
  String get settingsDownload;

  /// Settings section - visual customization
  ///
  /// In zh, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// Settings section - app options
  ///
  /// In zh, this message translates to:
  /// **'Options'**
  String get settingsOptions;

  /// Settings section - extension management
  ///
  /// In zh, this message translates to:
  /// **'Extensions'**
  String get settingsExtensions;

  /// Settings section - app info
  ///
  /// In zh, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// Download settings page title
  ///
  /// In zh, this message translates to:
  /// **'Download'**
  String get downloadTitle;

  /// Subtitle for ask quality toggle
  ///
  /// In zh, this message translates to:
  /// **'Show quality picker for each download'**
  String get downloadAskQualitySubtitle;

  /// Setting for output filename pattern
  ///
  /// In zh, this message translates to:
  /// **'Filename Format'**
  String get downloadFilenameFormat;

  /// Setting for output filename pattern for singles/EPs
  ///
  /// In zh, this message translates to:
  /// **'Single Filename Format'**
  String get downloadSingleFilenameFormat;

  /// Subtitle description for single filename format setting
  ///
  /// In zh, this message translates to:
  /// **'Filename pattern for singles and EPs. Uses the same tags as the album format.'**
  String get downloadSingleFilenameFormatDescription;

  /// Title of the folder organization picker bottom sheet
  ///
  /// In zh, this message translates to:
  /// **'Folder Organization'**
  String get downloadFolderOrganization;

  /// Appearance settings page title
  ///
  /// In zh, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// Follow system theme
  ///
  /// In zh, this message translates to:
  /// **'System'**
  String get appearanceThemeSystem;

  /// Light theme
  ///
  /// In zh, this message translates to:
  /// **'Light'**
  String get appearanceThemeLight;

  /// Dark theme
  ///
  /// In zh, this message translates to:
  /// **'Dark'**
  String get appearanceThemeDark;

  /// Material You dynamic colors
  ///
  /// In zh, this message translates to:
  /// **'Dynamic Color'**
  String get appearanceDynamicColor;

  /// Subtitle for dynamic color
  ///
  /// In zh, this message translates to:
  /// **'Use colors from your wallpaper'**
  String get appearanceDynamicColorSubtitle;

  /// Layout style for history
  ///
  /// In zh, this message translates to:
  /// **'History View'**
  String get appearanceHistoryView;

  /// List layout option
  ///
  /// In zh, this message translates to:
  /// **'List'**
  String get appearanceHistoryViewList;

  /// Grid layout option
  ///
  /// In zh, this message translates to:
  /// **'Grid'**
  String get appearanceHistoryViewGrid;

  /// Options settings page title
  ///
  /// In zh, this message translates to:
  /// **'Options'**
  String get optionsTitle;

  /// Main search provider setting
  ///
  /// In zh, this message translates to:
  /// **'Primary Provider'**
  String get optionsPrimaryProvider;

  /// Subtitle for primary provider
  ///
  /// In zh, this message translates to:
  /// **'Service used when searching by track name.'**
  String get optionsPrimaryProviderSubtitle;

  /// Shows active extension name
  ///
  /// In zh, this message translates to:
  /// **'Using extension: {extensionName}'**
  String optionsUsingExtension(String extensionName);

  /// Title for the preferred default search tab setting
  ///
  /// In zh, this message translates to:
  /// **'Default Search Tab'**
  String get optionsDefaultSearchTab;

  /// Subtitle for the preferred default search tab setting
  ///
  /// In zh, this message translates to:
  /// **'Choose which tab opens first for new search results.'**
  String get optionsDefaultSearchTabSubtitle;

  /// Hint to switch back to built-in providers
  ///
  /// In zh, this message translates to:
  /// **'Tap Deezer or Spotify to switch back from extension'**
  String get optionsSwitchBack;

  /// Auto-retry with other services
  ///
  /// In zh, this message translates to:
  /// **'Auto Fallback'**
  String get optionsAutoFallback;

  /// Subtitle for auto fallback
  ///
  /// In zh, this message translates to:
  /// **'Try other services if download fails'**
  String get optionsAutoFallbackSubtitle;

  /// Enable extension download providers
  ///
  /// In zh, this message translates to:
  /// **'Use Extension Providers'**
  String get optionsUseExtensionProviders;

  /// Status when extension providers enabled
  ///
  /// In zh, this message translates to:
  /// **'Extensions will be tried first'**
  String get optionsUseExtensionProvidersOn;

  /// Status when extension providers disabled
  ///
  /// In zh, this message translates to:
  /// **'Using built-in providers only'**
  String get optionsUseExtensionProvidersOff;

  /// Embed lyrics in audio files
  ///
  /// In zh, this message translates to:
  /// **'Embed Lyrics'**
  String get optionsEmbedLyrics;

  /// Subtitle for embed lyrics
  ///
  /// In zh, this message translates to:
  /// **'Embed synced lyrics into FLAC files'**
  String get optionsEmbedLyricsSubtitle;

  /// Download highest quality album art
  ///
  /// In zh, this message translates to:
  /// **'Max Quality Cover'**
  String get optionsMaxQualityCover;

  /// Subtitle for max quality cover
  ///
  /// In zh, this message translates to:
  /// **'Download highest resolution cover art'**
  String get optionsMaxQualityCoverSubtitle;

  /// Title for ReplayGain setting toggle
  ///
  /// In zh, this message translates to:
  /// **'ReplayGain'**
  String get optionsReplayGain;

  /// Subtitle when ReplayGain is enabled
  ///
  /// In zh, this message translates to:
  /// **'Scan loudness and embed ReplayGain tags (EBU R128)'**
  String get optionsReplayGainSubtitleOn;

  /// Subtitle when ReplayGain is disabled
  ///
  /// In zh, this message translates to:
  /// **'Disabled: no loudness normalization tags'**
  String get optionsReplayGainSubtitleOff;

  /// Setting title for how artist metadata is written into files
  ///
  /// In zh, this message translates to:
  /// **'Artist Tag Mode'**
  String get optionsArtistTagMode;

  /// Bottom-sheet description for artist tag mode setting
  ///
  /// In zh, this message translates to:
  /// **'Choose how multiple artists are written into embedded tags.'**
  String get optionsArtistTagModeDescription;

  /// Artist tag mode option that joins multiple artists into one value
  ///
  /// In zh, this message translates to:
  /// **'Single joined value'**
  String get optionsArtistTagModeJoined;

  /// Subtitle for joined artist tag mode
  ///
  /// In zh, this message translates to:
  /// **'Write one ARTIST value like \"Artist A, Artist B\" for maximum player compatibility.'**
  String get optionsArtistTagModeJoinedSubtitle;

  /// Artist tag mode option that writes repeated ARTIST tags for Vorbis formats
  ///
  /// In zh, this message translates to:
  /// **'Split tags for FLAC/Opus'**
  String get optionsArtistTagModeSplitVorbis;

  /// Subtitle for split Vorbis artist tag mode
  ///
  /// In zh, this message translates to:
  /// **'Write one artist tag per artist for FLAC and Opus; MP3 and M4A stay joined.'**
  String get optionsArtistTagModeSplitVorbisSubtitle;

  /// Number of parallel downloads
  ///
  /// In zh, this message translates to:
  /// **'Concurrent Downloads'**
  String get optionsConcurrentDownloads;

  /// Download one at a time
  ///
  /// In zh, this message translates to:
  /// **'Sequential (1 at a time)'**
  String get optionsConcurrentSequential;

  /// Multiple parallel downloads
  ///
  /// In zh, this message translates to:
  /// **'{count} parallel downloads'**
  String optionsConcurrentParallel(int count);

  /// Warning about rate limits
  ///
  /// In zh, this message translates to:
  /// **'Parallel downloads may trigger rate limiting'**
  String get optionsConcurrentWarning;

  /// Show/hide store tab
  ///
  /// In zh, this message translates to:
  /// **'Extension Repo'**
  String get optionsExtensionStore;

  /// Subtitle for extension store toggle
  ///
  /// In zh, this message translates to:
  /// **'Show Repo tab in navigation'**
  String get optionsExtensionStoreSubtitle;

  /// Auto update check toggle
  ///
  /// In zh, this message translates to:
  /// **'Check for Updates'**
  String get optionsCheckUpdates;

  /// Subtitle for update check
  ///
  /// In zh, this message translates to:
  /// **'Notify when new version is available'**
  String get optionsCheckUpdatesSubtitle;

  /// Stable vs preview releases
  ///
  /// In zh, this message translates to:
  /// **'Update Channel'**
  String get optionsUpdateChannel;

  /// Only stable updates
  ///
  /// In zh, this message translates to:
  /// **'Stable releases only'**
  String get optionsUpdateChannelStable;

  /// Include beta/preview updates
  ///
  /// In zh, this message translates to:
  /// **'Get preview releases'**
  String get optionsUpdateChannelPreview;

  /// Warning about preview channel
  ///
  /// In zh, this message translates to:
  /// **'Preview may contain bugs or incomplete features'**
  String get optionsUpdateChannelWarning;

  /// Delete all download history
  ///
  /// In zh, this message translates to:
  /// **'Clear Download History'**
  String get optionsClearHistory;

  /// Subtitle for clear history
  ///
  /// In zh, this message translates to:
  /// **'Remove all downloaded tracks from history'**
  String get optionsClearHistorySubtitle;

  /// Enable verbose logs for debugging
  ///
  /// In zh, this message translates to:
  /// **'Detailed Logging'**
  String get optionsDetailedLogging;

  /// Status when logging enabled
  ///
  /// In zh, this message translates to:
  /// **'Detailed logs are being recorded'**
  String get optionsDetailedLoggingOn;

  /// Status when logging disabled
  ///
  /// In zh, this message translates to:
  /// **'Enable for bug reports'**
  String get optionsDetailedLoggingOff;

  /// Spotify API credentials setting
  ///
  /// In zh, this message translates to:
  /// **'Spotify Credentials'**
  String get optionsSpotifyCredentials;

  /// Shows configured client ID preview
  ///
  /// In zh, this message translates to:
  /// **'Client ID: {clientId}...'**
  String optionsSpotifyCredentialsConfigured(String clientId);

  /// Prompt to set up credentials
  ///
  /// In zh, this message translates to:
  /// **'Required - tap to configure'**
  String get optionsSpotifyCredentialsRequired;

  /// Info about Spotify API requirement
  ///
  /// In zh, this message translates to:
  /// **'Spotify requires your own API credentials. Get them free from developer.spotify.com'**
  String get optionsSpotifyWarning;

  /// Warning about Spotify API deprecation
  ///
  /// In zh, this message translates to:
  /// **'Spotify search will be deprecated on March 3, 2026 due to Spotify API changes. Please switch to Deezer.'**
  String get optionsSpotifyDeprecationWarning;

  /// Extensions page title
  ///
  /// In zh, this message translates to:
  /// **'Extensions'**
  String get extensionsTitle;

  /// Extension status - inactive
  ///
  /// In zh, this message translates to:
  /// **'Disabled'**
  String get extensionsDisabled;

  /// Extension version display
  ///
  /// In zh, this message translates to:
  /// **'Version {version}'**
  String extensionsVersion(String version);

  /// Extension author credit
  ///
  /// In zh, this message translates to:
  /// **'by {author}'**
  String extensionsAuthor(String author);

  /// Uninstall extension button
  ///
  /// In zh, this message translates to:
  /// **'Uninstall'**
  String get extensionsUninstall;

  /// Store screen title
  ///
  /// In zh, this message translates to:
  /// **'Extension Repo'**
  String get storeTitle;

  /// Store search placeholder
  ///
  /// In zh, this message translates to:
  /// **'Search extensions...'**
  String get storeSearch;

  /// Install extension button
  ///
  /// In zh, this message translates to:
  /// **'Install'**
  String get storeInstall;

  /// Already installed badge
  ///
  /// In zh, this message translates to:
  /// **'Installed'**
  String get storeInstalled;

  /// Update available button
  ///
  /// In zh, this message translates to:
  /// **'Update'**
  String get storeUpdate;

  /// About page title
  ///
  /// In zh, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// Section for contributors
  ///
  /// In zh, this message translates to:
  /// **'Contributors'**
  String get aboutContributors;

  /// Role description for mobile dev
  ///
  /// In zh, this message translates to:
  /// **'Mobile version developer'**
  String get aboutMobileDeveloper;

  /// Role description for original creator
  ///
  /// In zh, this message translates to:
  /// **'Creator of the original SpotiFLAC'**
  String get aboutOriginalCreator;

  /// Role description for logo artist
  ///
  /// In zh, this message translates to:
  /// **'The talented artist who created our beautiful app logo!'**
  String get aboutLogoArtist;

  /// Section for translators
  ///
  /// In zh, this message translates to:
  /// **'Translators'**
  String get aboutTranslators;

  /// Section for special thanks
  ///
  /// In zh, this message translates to:
  /// **'Special Thanks'**
  String get aboutSpecialThanks;

  /// Section for external links
  ///
  /// In zh, this message translates to:
  /// **'Links'**
  String get aboutLinks;

  /// Link to mobile GitHub repo
  ///
  /// In zh, this message translates to:
  /// **'Mobile source code'**
  String get aboutMobileSource;

  /// Link to PC GitHub repo
  ///
  /// In zh, this message translates to:
  /// **'PC source code'**
  String get aboutPCSource;

  /// Link to Keep Android Open campaign website
  ///
  /// In zh, this message translates to:
  /// **'Keep Android Open'**
  String get aboutKeepAndroidOpen;

  /// Link to report bugs
  ///
  /// In zh, this message translates to:
  /// **'Report an issue'**
  String get aboutReportIssue;

  /// Subtitle for report issue
  ///
  /// In zh, this message translates to:
  /// **'Report any problems you encounter'**
  String get aboutReportIssueSubtitle;

  /// Link to suggest features
  ///
  /// In zh, this message translates to:
  /// **'Feature request'**
  String get aboutFeatureRequest;

  /// Subtitle for feature request
  ///
  /// In zh, this message translates to:
  /// **'Suggest new features for the app'**
  String get aboutFeatureRequestSubtitle;

  /// Link to Telegram channel
  ///
  /// In zh, this message translates to:
  /// **'Telegram Channel'**
  String get aboutTelegramChannel;

  /// Subtitle for Telegram channel
  ///
  /// In zh, this message translates to:
  /// **'Announcements and updates'**
  String get aboutTelegramChannelSubtitle;

  /// Link to Telegram chat group
  ///
  /// In zh, this message translates to:
  /// **'Telegram Community'**
  String get aboutTelegramChat;

  /// Subtitle for Telegram chat
  ///
  /// In zh, this message translates to:
  /// **'Chat with other users'**
  String get aboutTelegramChatSubtitle;

  /// Section for social links
  ///
  /// In zh, this message translates to:
  /// **'Social'**
  String get aboutSocial;

  /// Section for app info
  ///
  /// In zh, this message translates to:
  /// **'App'**
  String get aboutApp;

  /// Version info label
  ///
  /// In zh, this message translates to:
  /// **'Version'**
  String get aboutVersion;

  /// Credit description for binimum
  ///
  /// In zh, this message translates to:
  /// **'The creator of QQDL & HiFi API. Without this API, Tidal downloads wouldn\'t exist!'**
  String get aboutBinimumDesc;

  /// Credit description for sachinsenal0x64
  ///
  /// In zh, this message translates to:
  /// **'The original HiFi project creator. The foundation of Tidal integration!'**
  String get aboutSachinsenalDesc;

  /// Credit description for sjdonado
  ///
  /// In zh, this message translates to:
  /// **'Creator of I Don\'t Have Spotify (IDHS). The fallback link resolver that saves the day!'**
  String get aboutSjdonadoDesc;

  /// Name of Qobuz API service - DO NOT TRANSLATE
  ///
  /// In zh, this message translates to:
  /// **'DAB Music'**
  String get aboutDabMusic;

  /// Credit for DAB Music API
  ///
  /// In zh, this message translates to:
  /// **'The best Qobuz streaming API. Hi-Res downloads wouldn\'t be possible without this!'**
  String get aboutDabMusicDesc;

  /// Name of SpotiSaver API service - DO NOT TRANSLATE
  ///
  /// In zh, this message translates to:
  /// **'SpotiSaver'**
  String get aboutSpotiSaver;

  /// Credit for SpotiSaver API
  ///
  /// In zh, this message translates to:
  /// **'Tidal Hi-Res FLAC streaming endpoints. A key piece of the lossless puzzle!'**
  String get aboutSpotiSaverDesc;

  /// App description in header card
  ///
  /// In zh, this message translates to:
  /// **'Download Spotify tracks in lossless quality from Tidal and Qobuz.'**
  String get aboutAppDescription;

  /// Section header for artist albums
  ///
  /// In zh, this message translates to:
  /// **'Albums'**
  String get artistAlbums;

  /// Section header for singles/EPs
  ///
  /// In zh, this message translates to:
  /// **'Singles & EPs'**
  String get artistSingles;

  /// Section header for compilations
  ///
  /// In zh, this message translates to:
  /// **'Compilations'**
  String get artistCompilations;

  /// Section header for popular/top tracks
  ///
  /// In zh, this message translates to:
  /// **'Popular'**
  String get artistPopular;

  /// Monthly listener count display
  ///
  /// In zh, this message translates to:
  /// **'{count} monthly listeners'**
  String artistMonthlyListeners(String count);

  /// Metadata field - download service used
  ///
  /// In zh, this message translates to:
  /// **'Service'**
  String get trackMetadataService;

  /// Action button - play track
  ///
  /// In zh, this message translates to:
  /// **'Play'**
  String get trackMetadataPlay;

  /// Action button - share track
  ///
  /// In zh, this message translates to:
  /// **'Share'**
  String get trackMetadataShare;

  /// Action button - delete track
  ///
  /// In zh, this message translates to:
  /// **'Delete'**
  String get trackMetadataDelete;

  /// Button to request permission
  ///
  /// In zh, this message translates to:
  /// **'Grant Permission'**
  String get setupGrantPermission;

  /// Skip current step button
  ///
  /// In zh, this message translates to:
  /// **'Skip for now'**
  String get setupSkip;

  /// Title when storage access needed
  ///
  /// In zh, this message translates to:
  /// **'Storage Access Required'**
  String get setupStorageAccessRequired;

  /// Android 11+ specific explanation
  ///
  /// In zh, this message translates to:
  /// **'Android 11+ requires \"All files access\" permission to save files to your chosen download folder.'**
  String get setupStorageAccessMessageAndroid11;

  /// Button to open system settings
  ///
  /// In zh, this message translates to:
  /// **'Open Settings'**
  String get setupOpenSettings;

  /// Error when permission denied
  ///
  /// In zh, this message translates to:
  /// **'Permission denied. Please grant all permissions to continue.'**
  String get setupPermissionDeniedMessage;

  /// Generic permission required title
  ///
  /// In zh, this message translates to:
  /// **'{permissionType} Permission Required'**
  String setupPermissionRequired(String permissionType);

  /// Generic permission required message
  ///
  /// In zh, this message translates to:
  /// **'{permissionType} permission is required for the best experience. You can change this later in Settings.'**
  String setupPermissionRequiredMessage(String permissionType);

  /// Dialog title for default folder
  ///
  /// In zh, this message translates to:
  /// **'Use Default Folder?'**
  String get setupUseDefaultFolder;

  /// Prompt when no folder selected
  ///
  /// In zh, this message translates to:
  /// **'No folder selected. Would you like to use the default Music folder?'**
  String get setupNoFolderSelected;

  /// Button to use default folder
  ///
  /// In zh, this message translates to:
  /// **'Use Default'**
  String get setupUseDefault;

  /// Download location dialog title
  ///
  /// In zh, this message translates to:
  /// **'Download Location'**
  String get setupDownloadLocationTitle;

  /// iOS-specific folder info
  ///
  /// In zh, this message translates to:
  /// **'On iOS, downloads are saved to the app\'s Documents folder. You can access them via the Files app.'**
  String get setupDownloadLocationIosMessage;

  /// iOS documents folder option
  ///
  /// In zh, this message translates to:
  /// **'App Documents Folder'**
  String get setupAppDocumentsFolder;

  /// Subtitle for documents folder
  ///
  /// In zh, this message translates to:
  /// **'Recommended - accessible via Files app'**
  String get setupAppDocumentsFolderSubtitle;

  /// iOS file picker option
  ///
  /// In zh, this message translates to:
  /// **'Choose from Files'**
  String get setupChooseFromFiles;

  /// Subtitle for file picker
  ///
  /// In zh, this message translates to:
  /// **'Select iCloud or other location'**
  String get setupChooseFromFilesSubtitle;

  /// iOS folder selection warning
  ///
  /// In zh, this message translates to:
  /// **'iOS limitation: Empty folders cannot be selected. Choose a folder with at least one file.'**
  String get setupIosEmptyFolderWarning;

  /// Error when user selects iCloud Drive on iOS
  ///
  /// In zh, this message translates to:
  /// **'iCloud Drive is not supported. Please use the app Documents folder.'**
  String get setupIcloudNotSupported;

  /// App tagline in setup
  ///
  /// In zh, this message translates to:
  /// **'Download Spotify tracks in FLAC'**
  String get setupDownloadInFlac;

  /// Success message for storage permission
  ///
  /// In zh, this message translates to:
  /// **'Storage Permission Granted!'**
  String get setupStorageGranted;

  /// Title when storage permission needed
  ///
  /// In zh, this message translates to:
  /// **'Storage Permission Required'**
  String get setupStorageRequired;

  /// Explanation for storage permission
  ///
  /// In zh, this message translates to:
  /// **'SpotiFLAC needs storage permission to save your downloaded music files.'**
  String get setupStorageDescription;

  /// Success message for notification permission
  ///
  /// In zh, this message translates to:
  /// **'Notification Permission Granted!'**
  String get setupNotificationGranted;

  /// Button to enable notifications
  ///
  /// In zh, this message translates to:
  /// **'Enable Notifications'**
  String get setupNotificationEnable;

  /// Button to choose folder
  ///
  /// In zh, this message translates to:
  /// **'Choose Download Folder'**
  String get setupFolderChoose;

  /// Explanation for folder selection
  ///
  /// In zh, this message translates to:
  /// **'Select a folder where your downloaded music will be saved.'**
  String get setupFolderDescription;

  /// Button to select folder
  ///
  /// In zh, this message translates to:
  /// **'Select Folder'**
  String get setupSelectFolder;

  /// Button to enable notifications
  ///
  /// In zh, this message translates to:
  /// **'Enable Notifications'**
  String get setupEnableNotifications;

  /// Detailed notification explanation
  ///
  /// In zh, this message translates to:
  /// **'Get notified about download progress and completion. This helps you track downloads when the app is in background.'**
  String get setupNotificationBackgroundDescription;

  /// Skip button text
  ///
  /// In zh, this message translates to:
  /// **'Skip for now'**
  String get setupSkipForNow;

  /// Next button text
  ///
  /// In zh, this message translates to:
  /// **'Next'**
  String get setupNext;

  /// Final setup button
  ///
  /// In zh, this message translates to:
  /// **'Get Started'**
  String get setupGetStarted;

  /// Instruction for file access permission
  ///
  /// In zh, this message translates to:
  /// **'Please enable \"Allow access to manage all files\" in the next screen.'**
  String get setupAllowAccessToManageFiles;

  /// Dialog button - cancel action
  ///
  /// In zh, this message translates to:
  /// **'Cancel'**
  String get dialogCancel;

  /// Dialog button - save changes
  ///
  /// In zh, this message translates to:
  /// **'Save'**
  String get dialogSave;

  /// Dialog button - delete item
  ///
  /// In zh, this message translates to:
  /// **'Delete'**
  String get dialogDelete;

  /// Dialog button - retry action
  ///
  /// In zh, this message translates to:
  /// **'Retry'**
  String get dialogRetry;

  /// Dialog button - clear items
  ///
  /// In zh, this message translates to:
  /// **'Clear'**
  String get dialogClear;

  /// Dialog button - action completed
  ///
  /// In zh, this message translates to:
  /// **'Done'**
  String get dialogDone;

  /// Dialog button - import data
  ///
  /// In zh, this message translates to:
  /// **'Import'**
  String get dialogImport;

  /// Confirm button in Download All dialog
  ///
  /// In zh, this message translates to:
  /// **'Download'**
  String get dialogDownload;

  /// Dialog button - discard changes
  ///
  /// In zh, this message translates to:
  /// **'Discard'**
  String get dialogDiscard;

  /// Dialog button - remove item
  ///
  /// In zh, this message translates to:
  /// **'Remove'**
  String get dialogRemove;

  /// Dialog button - uninstall extension
  ///
  /// In zh, this message translates to:
  /// **'Uninstall'**
  String get dialogUninstall;

  /// Dialog title - unsaved changes warning
  ///
  /// In zh, this message translates to:
  /// **'Discard Changes?'**
  String get dialogDiscardChanges;

  /// Dialog message - unsaved changes
  ///
  /// In zh, this message translates to:
  /// **'You have unsaved changes. Do you want to discard them?'**
  String get dialogUnsavedChanges;

  /// Dialog title - clear all items
  ///
  /// In zh, this message translates to:
  /// **'Clear All'**
  String get dialogClearAll;

  /// Dialog title - uninstall extension
  ///
  /// In zh, this message translates to:
  /// **'Remove Extension'**
  String get dialogRemoveExtension;

  /// Dialog message - uninstall confirmation
  ///
  /// In zh, this message translates to:
  /// **'Are you sure you want to remove this extension? This cannot be undone.'**
  String get dialogRemoveExtensionMessage;

  /// Dialog title - uninstall extension
  ///
  /// In zh, this message translates to:
  /// **'Uninstall Extension?'**
  String get dialogUninstallExtension;

  /// Dialog message - uninstall specific extension
  ///
  /// In zh, this message translates to:
  /// **'Are you sure you want to remove {extensionName}?'**
  String dialogUninstallExtensionMessage(String extensionName);

  /// Dialog title - clear download history
  ///
  /// In zh, this message translates to:
  /// **'Clear History'**
  String get dialogClearHistoryTitle;

  /// Dialog message - clear history confirmation
  ///
  /// In zh, this message translates to:
  /// **'Are you sure you want to clear all download history? This cannot be undone.'**
  String get dialogClearHistoryMessage;

  /// Dialog title - delete selected items
  ///
  /// In zh, this message translates to:
  /// **'Delete Selected'**
  String get dialogDeleteSelectedTitle;

  /// Dialog message - delete selected tracks
  ///
  /// In zh, this message translates to:
  /// **'Delete {count} {count, plural, =1{track} other{tracks}} from history?\n\nThis will also delete the files from storage.'**
  String dialogDeleteSelectedMessage(int count);

  /// Dialog title - import CSV playlist
  ///
  /// In zh, this message translates to:
  /// **'Import Playlist'**
  String get dialogImportPlaylistTitle;

  /// Dialog message - import playlist confirmation
  ///
  /// In zh, this message translates to:
  /// **'Found {count} tracks in CSV. Add them to download queue?'**
  String dialogImportPlaylistMessage(int count);

  /// Label shown in quality picker for CSV import
  ///
  /// In zh, this message translates to:
  /// **'{count} tracks from CSV'**
  String csvImportTracks(int count);

  /// Snackbar - track added to download queue
  ///
  /// In zh, this message translates to:
  /// **'Added \"{trackName}\" to queue'**
  String snackbarAddedToQueue(String trackName);

  /// Snackbar - multiple tracks added to queue
  ///
  /// In zh, this message translates to:
  /// **'Added {count} tracks to queue'**
  String snackbarAddedTracksToQueue(int count);

  /// Snackbar - track already exists
  ///
  /// In zh, this message translates to:
  /// **'\"{trackName}\" already downloaded'**
  String snackbarAlreadyDownloaded(String trackName);

  /// Snackbar - track already exists in local library
  ///
  /// In zh, this message translates to:
  /// **'\"{trackName}\" already exists in your library'**
  String snackbarAlreadyInLibrary(String trackName);

  /// Snackbar - history deleted
  ///
  /// In zh, this message translates to:
  /// **'History cleared'**
  String get snackbarHistoryCleared;

  /// Snackbar - Spotify credentials saved
  ///
  /// In zh, this message translates to:
  /// **'Credentials saved'**
  String get snackbarCredentialsSaved;

  /// Snackbar - Spotify credentials removed
  ///
  /// In zh, this message translates to:
  /// **'Credentials cleared'**
  String get snackbarCredentialsCleared;

  /// Snackbar - tracks deleted
  ///
  /// In zh, this message translates to:
  /// **'Deleted {count} {count, plural, =1{track} other{tracks}}'**
  String snackbarDeletedTracks(int count);

  /// Snackbar - file open error
  ///
  /// In zh, this message translates to:
  /// **'Cannot open file: {error}'**
  String snackbarCannotOpenFile(String error);

  /// Snackbar - validation error
  ///
  /// In zh, this message translates to:
  /// **'Please fill all fields'**
  String get snackbarFillAllFields;

  /// Snackbar action - view download queue
  ///
  /// In zh, this message translates to:
  /// **'View Queue'**
  String get snackbarViewQueue;

  /// Snackbar - URL copied
  ///
  /// In zh, this message translates to:
  /// **'{platform} URL copied to clipboard'**
  String snackbarUrlCopied(String platform);

  /// Snackbar - file doesn't exist
  ///
  /// In zh, this message translates to:
  /// **'File not found'**
  String get snackbarFileNotFound;

  /// Snackbar - wrong file type selected
  ///
  /// In zh, this message translates to:
  /// **'Please select a .spotiflac-ext file'**
  String get snackbarSelectExtFile;

  /// Snackbar - provider order saved
  ///
  /// In zh, this message translates to:
  /// **'Provider priority saved'**
  String get snackbarProviderPrioritySaved;

  /// Snackbar - metadata provider order saved
  ///
  /// In zh, this message translates to:
  /// **'Metadata provider priority saved'**
  String get snackbarMetadataProviderSaved;

  /// Snackbar - extension installed successfully
  ///
  /// In zh, this message translates to:
  /// **'{extensionName} installed.'**
  String snackbarExtensionInstalled(String extensionName);

  /// Snackbar - extension updated successfully
  ///
  /// In zh, this message translates to:
  /// **'{extensionName} updated.'**
  String snackbarExtensionUpdated(String extensionName);

  /// Snackbar - extension install error
  ///
  /// In zh, this message translates to:
  /// **'Failed to install extension'**
  String get snackbarFailedToInstall;

  /// Snackbar - extension update error
  ///
  /// In zh, this message translates to:
  /// **'Failed to update extension'**
  String get snackbarFailedToUpdate;

  /// Error title - too many requests
  ///
  /// In zh, this message translates to:
  /// **'Rate Limited'**
  String get errorRateLimited;

  /// Error message - rate limit explanation
  ///
  /// In zh, this message translates to:
  /// **'Too many requests. Please wait a moment before searching again.'**
  String get errorRateLimitedMessage;

  /// Error - search returned no results
  ///
  /// In zh, this message translates to:
  /// **'No tracks found'**
  String get errorNoTracksFound;

  /// Error title - URL not handled by any extension or service
  ///
  /// In zh, this message translates to:
  /// **'Link not recognized'**
  String get errorUrlNotRecognized;

  /// Error message - URL not recognized explanation
  ///
  /// In zh, this message translates to:
  /// **'This link is not supported. Make sure the URL is correct and a compatible extension is installed.'**
  String get errorUrlNotRecognizedMessage;

  /// Error message - generic URL fetch failure
  ///
  /// In zh, this message translates to:
  /// **'Failed to load content from this link. Please try again.'**
  String get errorUrlFetchFailed;

  /// Error - extension source not available
  ///
  /// In zh, this message translates to:
  /// **'Cannot load {item}: missing extension source'**
  String errorMissingExtensionSource(String item);

  /// Action button - pause download
  ///
  /// In zh, this message translates to:
  /// **'Pause'**
  String get actionPause;

  /// Action button - resume download
  ///
  /// In zh, this message translates to:
  /// **'Resume'**
  String get actionResume;

  /// Action button - cancel operation
  ///
  /// In zh, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// Action button - select all items
  ///
  /// In zh, this message translates to:
  /// **'Select All'**
  String get actionSelectAll;

  /// Action button - deselect all
  ///
  /// In zh, this message translates to:
  /// **'Deselect'**
  String get actionDeselect;

  /// Action button - delete Spotify credentials
  ///
  /// In zh, this message translates to:
  /// **'Remove Credentials'**
  String get actionRemoveCredentials;

  /// Action button - save Spotify credentials
  ///
  /// In zh, this message translates to:
  /// **'Save Credentials'**
  String get actionSaveCredentials;

  /// Selection count indicator
  ///
  /// In zh, this message translates to:
  /// **'{count} selected'**
  String selectionSelected(int count);

  /// Status - all items selected
  ///
  /// In zh, this message translates to:
  /// **'All tracks selected'**
  String get selectionAllSelected;

  /// Placeholder when nothing selected
  ///
  /// In zh, this message translates to:
  /// **'Select tracks to delete'**
  String get selectionSelectToDelete;

  /// Progress indicator - loading track info
  ///
  /// In zh, this message translates to:
  /// **'Fetching metadata... {current}/{total}'**
  String progressFetchingMetadata(int current, int total);

  /// Progress indicator - parsing CSV file
  ///
  /// In zh, this message translates to:
  /// **'Reading CSV...'**
  String get progressReadingCsv;

  /// Search result category - songs
  ///
  /// In zh, this message translates to:
  /// **'Songs'**
  String get searchSongs;

  /// Search result category - artists
  ///
  /// In zh, this message translates to:
  /// **'Artists'**
  String get searchArtists;

  /// Search result category - albums
  ///
  /// In zh, this message translates to:
  /// **'Albums'**
  String get searchAlbums;

  /// Search result category - playlists
  ///
  /// In zh, this message translates to:
  /// **'Playlists'**
  String get searchPlaylists;

  /// Bottom sheet title for search sort options
  ///
  /// In zh, this message translates to:
  /// **'Sort Results'**
  String get searchSortTitle;

  /// Sort option - default API order
  ///
  /// In zh, this message translates to:
  /// **'Default'**
  String get searchSortDefault;

  /// Sort option - title ascending
  ///
  /// In zh, this message translates to:
  /// **'Title (A-Z)'**
  String get searchSortTitleAZ;

  /// Sort option - title descending
  ///
  /// In zh, this message translates to:
  /// **'Title (Z-A)'**
  String get searchSortTitleZA;

  /// Sort option - artist ascending
  ///
  /// In zh, this message translates to:
  /// **'Artist (A-Z)'**
  String get searchSortArtistAZ;

  /// Sort option - artist descending
  ///
  /// In zh, this message translates to:
  /// **'Artist (Z-A)'**
  String get searchSortArtistZA;

  /// Sort option - shortest duration first
  ///
  /// In zh, this message translates to:
  /// **'Duration (Shortest)'**
  String get searchSortDurationShort;

  /// Sort option - longest duration first
  ///
  /// In zh, this message translates to:
  /// **'Duration (Longest)'**
  String get searchSortDurationLong;

  /// Sort option - oldest release first
  ///
  /// In zh, this message translates to:
  /// **'Release Date (Oldest)'**
  String get searchSortDateOldest;

  /// Sort option - newest release first
  ///
  /// In zh, this message translates to:
  /// **'Release Date (Newest)'**
  String get searchSortDateNewest;

  /// Tooltip - play button
  ///
  /// In zh, this message translates to:
  /// **'Play'**
  String get tooltipPlay;

  /// Setting title - filename pattern
  ///
  /// In zh, this message translates to:
  /// **'Filename Format'**
  String get filenameFormat;

  /// Toggle label for showing advanced filename tags
  ///
  /// In zh, this message translates to:
  /// **'Show advanced tags'**
  String get filenameShowAdvancedTags;

  /// Description for advanced filename tag toggle
  ///
  /// In zh, this message translates to:
  /// **'Enable formatted tags for track padding and date patterns'**
  String get filenameShowAdvancedTagsDescription;

  /// Folder option - flat structure
  ///
  /// In zh, this message translates to:
  /// **'No organization'**
  String get folderOrganizationNone;

  /// Folder option - playlist folders
  ///
  /// In zh, this message translates to:
  /// **'By Playlist'**
  String get folderOrganizationByPlaylist;

  /// Subtitle for playlist folder option
  ///
  /// In zh, this message translates to:
  /// **'Separate folder for each playlist'**
  String get folderOrganizationByPlaylistSubtitle;

  /// Folder option - artist folders
  ///
  /// In zh, this message translates to:
  /// **'By Artist'**
  String get folderOrganizationByArtist;

  /// Folder option - album folders
  ///
  /// In zh, this message translates to:
  /// **'By Album'**
  String get folderOrganizationByAlbum;

  /// Folder option - nested folders
  ///
  /// In zh, this message translates to:
  /// **'Artist/Album'**
  String get folderOrganizationByArtistAlbum;

  /// Folder organization sheet description
  ///
  /// In zh, this message translates to:
  /// **'Organize downloaded files into folders'**
  String get folderOrganizationDescription;

  /// Subtitle for no organization option
  ///
  /// In zh, this message translates to:
  /// **'All files in download folder'**
  String get folderOrganizationNoneSubtitle;

  /// Subtitle for artist folder option
  ///
  /// In zh, this message translates to:
  /// **'Separate folder for each artist'**
  String get folderOrganizationByArtistSubtitle;

  /// Subtitle for album folder option
  ///
  /// In zh, this message translates to:
  /// **'Separate folder for each album'**
  String get folderOrganizationByAlbumSubtitle;

  /// Subtitle for nested folder option
  ///
  /// In zh, this message translates to:
  /// **'Nested folders for artist and album'**
  String get folderOrganizationByArtistAlbumSubtitle;

  /// Update dialog title
  ///
  /// In zh, this message translates to:
  /// **'Update Available'**
  String get updateAvailable;

  /// Update button - dismiss
  ///
  /// In zh, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// Update status - initializing
  ///
  /// In zh, this message translates to:
  /// **'Starting download...'**
  String get updateStartingDownload;

  /// Update error title
  ///
  /// In zh, this message translates to:
  /// **'Download failed'**
  String get updateDownloadFailed;

  /// Update error message
  ///
  /// In zh, this message translates to:
  /// **'Failed to download update'**
  String get updateFailedMessage;

  /// Update subtitle
  ///
  /// In zh, this message translates to:
  /// **'A new version is ready'**
  String get updateNewVersionReady;

  /// Label for current version
  ///
  /// In zh, this message translates to:
  /// **'Current'**
  String get updateCurrent;

  /// Label for new version
  ///
  /// In zh, this message translates to:
  /// **'New'**
  String get updateNew;

  /// Update status - downloading
  ///
  /// In zh, this message translates to:
  /// **'Downloading...'**
  String get updateDownloading;

  /// Changelog section title
  ///
  /// In zh, this message translates to:
  /// **'What\'s New'**
  String get updateWhatsNew;

  /// Update button - download and install
  ///
  /// In zh, this message translates to:
  /// **'Download & Install'**
  String get updateDownloadInstall;

  /// Update button - skip this version
  ///
  /// In zh, this message translates to:
  /// **'Don\'t remind'**
  String get updateDontRemind;

  /// Provider priority page title
  ///
  /// In zh, this message translates to:
  /// **'Provider Priority'**
  String get providerPriorityTitle;

  /// Provider priority page description
  ///
  /// In zh, this message translates to:
  /// **'Drag to reorder download providers. The app will try providers from top to bottom when downloading tracks.'**
  String get providerPriorityDescription;

  /// Info tip about fallback behavior
  ///
  /// In zh, this message translates to:
  /// **'If a track is not available on the first provider, the app will automatically try the next one.'**
  String get providerPriorityInfo;

  /// Section title for choosing which download extensions can be used as fallback providers
  ///
  /// In zh, this message translates to:
  /// **'Extension Fallback'**
  String get providerPriorityFallbackExtensionsTitle;

  /// Section description for extension fallback selection
  ///
  /// In zh, this message translates to:
  /// **'Choose which installed download extensions can be used during automatic fallback. Built-in providers still follow the priority order above.'**
  String get providerPriorityFallbackExtensionsDescription;

  /// Hint below the extension fallback selection list
  ///
  /// In zh, this message translates to:
  /// **'Only enabled extensions with download-provider capability are listed here.'**
  String get providerPriorityFallbackExtensionsHint;

  /// Label for built-in providers (Tidal/Qobuz)
  ///
  /// In zh, this message translates to:
  /// **'Built-in'**
  String get providerBuiltIn;

  /// Label for extension-provided providers
  ///
  /// In zh, this message translates to:
  /// **'Extension'**
  String get providerExtension;

  /// Metadata priority page title
  ///
  /// In zh, this message translates to:
  /// **'Metadata Priority'**
  String get metadataProviderPriorityTitle;

  /// Metadata priority page description
  ///
  /// In zh, this message translates to:
  /// **'Drag to reorder metadata providers. The app will try providers from top to bottom when searching for tracks and fetching metadata.'**
  String get metadataProviderPriorityDescription;

  /// Info tip about rate limits
  ///
  /// In zh, this message translates to:
  /// **'Deezer has no rate limits and is recommended as primary. Spotify may rate limit after many requests.'**
  String get metadataProviderPriorityInfo;

  /// Deezer provider description
  ///
  /// In zh, this message translates to:
  /// **'No rate limits'**
  String get metadataNoRateLimits;

  /// Spotify provider description
  ///
  /// In zh, this message translates to:
  /// **'May rate limit'**
  String get metadataMayRateLimit;

  /// Logs screen title
  ///
  /// In zh, this message translates to:
  /// **'Logs'**
  String get logTitle;

  /// Snackbar - logs copied
  ///
  /// In zh, this message translates to:
  /// **'Logs copied to clipboard'**
  String get logCopied;

  /// Log search placeholder
  ///
  /// In zh, this message translates to:
  /// **'Search logs...'**
  String get logSearchHint;

  /// Filter by log level
  ///
  /// In zh, this message translates to:
  /// **'Level'**
  String get logFilterLevel;

  /// Filter section title
  ///
  /// In zh, this message translates to:
  /// **'Filter'**
  String get logFilterSection;

  /// Share button tooltip
  ///
  /// In zh, this message translates to:
  /// **'Share logs'**
  String get logShareLogs;

  /// Clear button tooltip
  ///
  /// In zh, this message translates to:
  /// **'Clear logs'**
  String get logClearLogs;

  /// Clear logs dialog title
  ///
  /// In zh, this message translates to:
  /// **'Clear Logs'**
  String get logClearLogsTitle;

  /// Clear logs confirmation message
  ///
  /// In zh, this message translates to:
  /// **'Are you sure you want to clear all logs?'**
  String get logClearLogsMessage;

  /// Filter dialog title
  ///
  /// In zh, this message translates to:
  /// **'Filter logs by severity'**
  String get logFilterBySeverity;

  /// Empty state title
  ///
  /// In zh, this message translates to:
  /// **'No logs yet'**
  String get logNoLogsYet;

  /// Empty state subtitle
  ///
  /// In zh, this message translates to:
  /// **'Logs will appear here as you use the app'**
  String get logNoLogsYetSubtitle;

  /// Log count with filter active
  ///
  /// In zh, this message translates to:
  /// **'Entries ({count} filtered)'**
  String logEntriesFiltered(int count);

  /// Total log count
  ///
  /// In zh, this message translates to:
  /// **'Entries ({count})'**
  String logEntries(int count);

  /// Credentials dialog title
  ///
  /// In zh, this message translates to:
  /// **'Spotify Credentials'**
  String get credentialsTitle;

  /// Credentials dialog explanation
  ///
  /// In zh, this message translates to:
  /// **'Enter your Client ID and Secret to use your own Spotify application quota.'**
  String get credentialsDescription;

  /// Client ID field label - DO NOT TRANSLATE
  ///
  /// In zh, this message translates to:
  /// **'Client ID'**
  String get credentialsClientId;

  /// Client ID placeholder
  ///
  /// In zh, this message translates to:
  /// **'Paste Client ID'**
  String get credentialsClientIdHint;

  /// Client Secret field label - DO NOT TRANSLATE
  ///
  /// In zh, this message translates to:
  /// **'Client Secret'**
  String get credentialsClientSecret;

  /// Client Secret placeholder
  ///
  /// In zh, this message translates to:
  /// **'Paste Client Secret'**
  String get credentialsClientSecretHint;

  /// Update channel - stable releases
  ///
  /// In zh, this message translates to:
  /// **'Stable'**
  String get channelStable;

  /// Update channel - beta/preview releases
  ///
  /// In zh, this message translates to:
  /// **'Preview'**
  String get channelPreview;

  /// Settings section header
  ///
  /// In zh, this message translates to:
  /// **'Search Source'**
  String get sectionSearchSource;

  /// Settings section header
  ///
  /// In zh, this message translates to:
  /// **'Download'**
  String get sectionDownload;

  /// Settings section header
  ///
  /// In zh, this message translates to:
  /// **'Performance'**
  String get sectionPerformance;

  /// Settings section header
  ///
  /// In zh, this message translates to:
  /// **'App'**
  String get sectionApp;

  /// Settings section header
  ///
  /// In zh, this message translates to:
  /// **'Data'**
  String get sectionData;

  /// Settings section header
  ///
  /// In zh, this message translates to:
  /// **'Debug'**
  String get sectionDebug;

  /// Settings section header
  ///
  /// In zh, this message translates to:
  /// **'Service'**
  String get sectionService;

  /// Settings section header
  ///
  /// In zh, this message translates to:
  /// **'Audio Quality'**
  String get sectionAudioQuality;

  /// Settings section header
  ///
  /// In zh, this message translates to:
  /// **'File Settings'**
  String get sectionFileSettings;

  /// Settings section header
  ///
  /// In zh, this message translates to:
  /// **'Lyrics'**
  String get sectionLyrics;

  /// Setting - how to save lyrics
  ///
  /// In zh, this message translates to:
  /// **'Lyrics Mode'**
  String get lyricsMode;

  /// Lyrics mode picker description
  ///
  /// In zh, this message translates to:
  /// **'Choose how lyrics are saved with your downloads'**
  String get lyricsModeDescription;

  /// Lyrics mode option - embed in audio file
  ///
  /// In zh, this message translates to:
  /// **'Embed in file'**
  String get lyricsModeEmbed;

  /// Subtitle for embed option
  ///
  /// In zh, this message translates to:
  /// **'Lyrics stored inside FLAC metadata'**
  String get lyricsModeEmbedSubtitle;

  /// Lyrics mode option - separate LRC file
  ///
  /// In zh, this message translates to:
  /// **'External .lrc file'**
  String get lyricsModeExternal;

  /// Subtitle for external option
  ///
  /// In zh, this message translates to:
  /// **'Separate .lrc file for players like Samsung Music'**
  String get lyricsModeExternalSubtitle;

  /// Lyrics mode option - embed and external
  ///
  /// In zh, this message translates to:
  /// **'Both'**
  String get lyricsModeBoth;

  /// Subtitle for both option
  ///
  /// In zh, this message translates to:
  /// **'Embed and save .lrc file'**
  String get lyricsModeBothSubtitle;

  /// Settings section header
  ///
  /// In zh, this message translates to:
  /// **'Color'**
  String get sectionColor;

  /// Settings section header
  ///
  /// In zh, this message translates to:
  /// **'Theme'**
  String get sectionTheme;

  /// Settings section header
  ///
  /// In zh, this message translates to:
  /// **'Layout'**
  String get sectionLayout;

  /// Settings section header for language
  ///
  /// In zh, this message translates to:
  /// **'Language'**
  String get sectionLanguage;

  /// Language setting title
  ///
  /// In zh, this message translates to:
  /// **'App Language'**
  String get appearanceLanguage;

  /// Appearance settings description
  ///
  /// In zh, this message translates to:
  /// **'Theme, colors, display'**
  String get settingsAppearanceSubtitle;

  /// Download settings description
  ///
  /// In zh, this message translates to:
  /// **'Service, quality, filename format'**
  String get settingsDownloadSubtitle;

  /// Options settings description
  ///
  /// In zh, this message translates to:
  /// **'Fallback, lyrics, cover art, updates'**
  String get settingsOptionsSubtitle;

  /// Extensions settings description
  ///
  /// In zh, this message translates to:
  /// **'Manage download providers'**
  String get settingsExtensionsSubtitle;

  /// Logs settings description
  ///
  /// In zh, this message translates to:
  /// **'View app logs for debugging'**
  String get settingsLogsSubtitle;

  /// Status when opening shared URL
  ///
  /// In zh, this message translates to:
  /// **'Loading shared link...'**
  String get loadingSharedLink;

  /// Exit confirmation message
  ///
  /// In zh, this message translates to:
  /// **'Press back again to exit'**
  String get pressBackAgainToExit;

  /// Download all button with count
  ///
  /// In zh, this message translates to:
  /// **'Download All ({count})'**
  String downloadAllCount(int count);

  /// Track count display
  ///
  /// In zh, this message translates to:
  /// **'{count, plural, =1{1 track} other{{count} tracks}}'**
  String tracksCount(int count);

  /// Action - copy file path
  ///
  /// In zh, this message translates to:
  /// **'Copy file path'**
  String get trackCopyFilePath;

  /// Action - delete downloaded file
  ///
  /// In zh, this message translates to:
  /// **'Remove from device'**
  String get trackRemoveFromDevice;

  /// Action - fetch lyrics
  ///
  /// In zh, this message translates to:
  /// **'Load Lyrics'**
  String get trackLoadLyrics;

  /// Tab title - track metadata
  ///
  /// In zh, this message translates to:
  /// **'Metadata'**
  String get trackMetadata;

  /// Tab title - file information
  ///
  /// In zh, this message translates to:
  /// **'File Info'**
  String get trackFileInfo;

  /// Tab title - lyrics
  ///
  /// In zh, this message translates to:
  /// **'Lyrics'**
  String get trackLyrics;

  /// Error - file doesn't exist
  ///
  /// In zh, this message translates to:
  /// **'File not found'**
  String get trackFileNotFound;

  /// Action - open track in Deezer app
  ///
  /// In zh, this message translates to:
  /// **'Open in Deezer'**
  String get trackOpenInDeezer;

  /// Action - open track in Spotify app
  ///
  /// In zh, this message translates to:
  /// **'Open in Spotify'**
  String get trackOpenInSpotify;

  /// Metadata label - track title
  ///
  /// In zh, this message translates to:
  /// **'Track name'**
  String get trackTrackName;

  /// Metadata label - artist name
  ///
  /// In zh, this message translates to:
  /// **'Artist'**
  String get trackArtist;

  /// Metadata label - album artist
  ///
  /// In zh, this message translates to:
  /// **'Album artist'**
  String get trackAlbumArtist;

  /// Metadata label - album name
  ///
  /// In zh, this message translates to:
  /// **'Album'**
  String get trackAlbum;

  /// Metadata label - track number
  ///
  /// In zh, this message translates to:
  /// **'Track number'**
  String get trackTrackNumber;

  /// Metadata label - disc number
  ///
  /// In zh, this message translates to:
  /// **'Disc number'**
  String get trackDiscNumber;

  /// Metadata label - track length
  ///
  /// In zh, this message translates to:
  /// **'Duration'**
  String get trackDuration;

  /// Metadata label - audio quality
  ///
  /// In zh, this message translates to:
  /// **'Audio quality'**
  String get trackAudioQuality;

  /// Metadata label - release date
  ///
  /// In zh, this message translates to:
  /// **'Release date'**
  String get trackReleaseDate;

  /// Metadata label - music genre
  ///
  /// In zh, this message translates to:
  /// **'Genre'**
  String get trackGenre;

  /// Metadata label - record label
  ///
  /// In zh, this message translates to:
  /// **'Label'**
  String get trackLabel;

  /// Metadata label - copyright information
  ///
  /// In zh, this message translates to:
  /// **'Copyright'**
  String get trackCopyright;

  /// Metadata label - download date
  ///
  /// In zh, this message translates to:
  /// **'Downloaded'**
  String get trackDownloaded;

  /// Action - copy lyrics to clipboard
  ///
  /// In zh, this message translates to:
  /// **'Copy lyrics'**
  String get trackCopyLyrics;

  /// Message when lyrics not found
  ///
  /// In zh, this message translates to:
  /// **'Lyrics not available for this track'**
  String get trackLyricsNotAvailable;

  /// Message when no embedded lyrics in audio file
  ///
  /// In zh, this message translates to:
  /// **'No lyrics found in this file'**
  String get trackLyricsNotInFile;

  /// Action - fetch lyrics from online providers
  ///
  /// In zh, this message translates to:
  /// **'Fetch from Online'**
  String get trackFetchOnlineLyrics;

  /// Message when lyrics request times out
  ///
  /// In zh, this message translates to:
  /// **'Request timed out. Try again later.'**
  String get trackLyricsTimeout;

  /// Message when lyrics loading fails
  ///
  /// In zh, this message translates to:
  /// **'Failed to load lyrics'**
  String get trackLyricsLoadFailed;

  /// Action - embed lyrics into audio file
  ///
  /// In zh, this message translates to:
  /// **'Embed Lyrics'**
  String get trackEmbedLyrics;

  /// Snackbar - lyrics saved to file
  ///
  /// In zh, this message translates to:
  /// **'Lyrics embedded successfully'**
  String get trackLyricsEmbedded;

  /// Message when track is instrumental (no lyrics)
  ///
  /// In zh, this message translates to:
  /// **'Instrumental track'**
  String get trackInstrumental;

  /// Snackbar - content copied
  ///
  /// In zh, this message translates to:
  /// **'Copied to clipboard'**
  String get trackCopiedToClipboard;

  /// Delete confirmation title
  ///
  /// In zh, this message translates to:
  /// **'Remove from device?'**
  String get trackDeleteConfirmTitle;

  /// Delete confirmation message
  ///
  /// In zh, this message translates to:
  /// **'This will permanently delete the downloaded file and remove it from your history.'**
  String get trackDeleteConfirmMessage;

  /// Relative date - today
  ///
  /// In zh, this message translates to:
  /// **'Today'**
  String get dateToday;

  /// Relative date - yesterday
  ///
  /// In zh, this message translates to:
  /// **'Yesterday'**
  String get dateYesterday;

  /// Relative date - days ago
  ///
  /// In zh, this message translates to:
  /// **'{count} days ago'**
  String dateDaysAgo(int count);

  /// Relative date - weeks ago
  ///
  /// In zh, this message translates to:
  /// **'{count} weeks ago'**
  String dateWeeksAgo(int count);

  /// Relative date - months ago
  ///
  /// In zh, this message translates to:
  /// **'{count} months ago'**
  String dateMonthsAgo(int count);

  /// Store filter - all extensions
  ///
  /// In zh, this message translates to:
  /// **'All'**
  String get storeFilterAll;

  /// Store filter - metadata providers
  ///
  /// In zh, this message translates to:
  /// **'Metadata'**
  String get storeFilterMetadata;

  /// Store filter - download providers
  ///
  /// In zh, this message translates to:
  /// **'Download'**
  String get storeFilterDownload;

  /// Store filter - utility extensions
  ///
  /// In zh, this message translates to:
  /// **'Utility'**
  String get storeFilterUtility;

  /// Store filter - lyrics providers
  ///
  /// In zh, this message translates to:
  /// **'Lyrics'**
  String get storeFilterLyrics;

  /// Store filter - integrations
  ///
  /// In zh, this message translates to:
  /// **'Integration'**
  String get storeFilterIntegration;

  /// Button to clear all filters
  ///
  /// In zh, this message translates to:
  /// **'Clear filters'**
  String get storeClearFilters;

  /// Store setup screen - heading when no repo is configured
  ///
  /// In zh, this message translates to:
  /// **'Add Extension Repository'**
  String get storeAddRepoTitle;

  /// Store setup screen - explanatory text
  ///
  /// In zh, this message translates to:
  /// **'Enter a GitHub repository URL that contains a registry.json file to browse and install extensions.'**
  String get storeAddRepoDescription;

  /// Label for the repository URL input field
  ///
  /// In zh, this message translates to:
  /// **'Repository URL'**
  String get storeRepoUrlLabel;

  /// Hint/placeholder for the repository URL input field
  ///
  /// In zh, this message translates to:
  /// **'https://github.com/user/repo'**
  String get storeRepoUrlHint;

  /// Helper text below the repository URL input field
  ///
  /// In zh, this message translates to:
  /// **'e.g. https://github.com/user/extensions-repo'**
  String get storeRepoUrlHelper;

  /// Button to submit a new repository URL
  ///
  /// In zh, this message translates to:
  /// **'Add Repository'**
  String get storeAddRepoButton;

  /// Tooltip for the change-repository icon button in the app bar
  ///
  /// In zh, this message translates to:
  /// **'Change repository'**
  String get storeChangeRepoTooltip;

  /// Title of the change/remove repository dialog
  ///
  /// In zh, this message translates to:
  /// **'Extension Repository'**
  String get storeRepoDialogTitle;

  /// Label shown above the current repository URL in the dialog
  ///
  /// In zh, this message translates to:
  /// **'Current repository:'**
  String get storeRepoDialogCurrent;

  /// Label for the new repository URL field inside the dialog
  ///
  /// In zh, this message translates to:
  /// **'New Repository URL'**
  String get storeNewRepoUrlLabel;

  /// Error heading when the store cannot be loaded
  ///
  /// In zh, this message translates to:
  /// **'Failed to load repository'**
  String get storeLoadError;

  /// Message when store has no extensions
  ///
  /// In zh, this message translates to:
  /// **'No extensions available'**
  String get storeEmptyNoExtensions;

  /// Message when search/filter returns no results
  ///
  /// In zh, this message translates to:
  /// **'No extensions found'**
  String get storeEmptyNoResults;

  /// Default search provider option
  ///
  /// In zh, this message translates to:
  /// **'Default (Deezer)'**
  String get extensionDefaultProvider;

  /// Subtitle for default provider
  ///
  /// In zh, this message translates to:
  /// **'Use built-in search'**
  String get extensionDefaultProviderSubtitle;

  /// Extension detail - author
  ///
  /// In zh, this message translates to:
  /// **'Author'**
  String get extensionAuthor;

  /// Extension detail - unique ID
  ///
  /// In zh, this message translates to:
  /// **'ID'**
  String get extensionId;

  /// Extension detail - error message
  ///
  /// In zh, this message translates to:
  /// **'Error'**
  String get extensionError;

  /// Section header - extension features
  ///
  /// In zh, this message translates to:
  /// **'Capabilities'**
  String get extensionCapabilities;

  /// Capability - provides metadata
  ///
  /// In zh, this message translates to:
  /// **'Metadata Provider'**
  String get extensionMetadataProvider;

  /// Capability - provides downloads
  ///
  /// In zh, this message translates to:
  /// **'Download Provider'**
  String get extensionDownloadProvider;

  /// Capability - provides lyrics
  ///
  /// In zh, this message translates to:
  /// **'Lyrics Provider'**
  String get extensionLyricsProvider;

  /// Capability - handles URLs
  ///
  /// In zh, this message translates to:
  /// **'URL Handler'**
  String get extensionUrlHandler;

  /// Capability - quality selection
  ///
  /// In zh, this message translates to:
  /// **'Quality Options'**
  String get extensionQualityOptions;

  /// Capability - post-processing
  ///
  /// In zh, this message translates to:
  /// **'Post-Processing Hooks'**
  String get extensionPostProcessingHooks;

  /// Section header - required permissions
  ///
  /// In zh, this message translates to:
  /// **'Permissions'**
  String get extensionPermissions;

  /// Section header - extension settings
  ///
  /// In zh, this message translates to:
  /// **'Settings'**
  String get extensionSettings;

  /// Button to uninstall extension
  ///
  /// In zh, this message translates to:
  /// **'Remove Extension'**
  String get extensionRemoveButton;

  /// Extension detail - last update
  ///
  /// In zh, this message translates to:
  /// **'Updated'**
  String get extensionUpdated;

  /// Extension detail - minimum app version
  ///
  /// In zh, this message translates to:
  /// **'Min App Version'**
  String get extensionMinAppVersion;

  /// Capability - custom track matching algorithm
  ///
  /// In zh, this message translates to:
  /// **'Custom Track Matching'**
  String get extensionCustomTrackMatching;

  /// Capability - post-download processing
  ///
  /// In zh, this message translates to:
  /// **'Post-Processing'**
  String get extensionPostProcessing;

  /// Post-processing hooks count
  ///
  /// In zh, this message translates to:
  /// **'{count} hook(s) available'**
  String extensionHooksAvailable(int count);

  /// URL patterns count
  ///
  /// In zh, this message translates to:
  /// **'{count} pattern(s)'**
  String extensionPatternsCount(int count);

  /// Track matching strategy name
  ///
  /// In zh, this message translates to:
  /// **'Strategy: {strategy}'**
  String extensionStrategy(String strategy);

  /// Section header - provider priority
  ///
  /// In zh, this message translates to:
  /// **'Provider Priority'**
  String get extensionsProviderPrioritySection;

  /// Section header - installed extensions
  ///
  /// In zh, this message translates to:
  /// **'Installed Extensions'**
  String get extensionsInstalledSection;

  /// Empty state - no extensions
  ///
  /// In zh, this message translates to:
  /// **'No extensions installed'**
  String get extensionsNoExtensions;

  /// Empty state subtitle
  ///
  /// In zh, this message translates to:
  /// **'Install .spotiflac-ext files to add new providers'**
  String get extensionsNoExtensionsSubtitle;

  /// Button to install extension from file
  ///
  /// In zh, this message translates to:
  /// **'Install Extension'**
  String get extensionsInstallButton;

  /// Security warning about extensions
  ///
  /// In zh, this message translates to:
  /// **'Extensions can add new metadata and download providers. Only install extensions from trusted sources.'**
  String get extensionsInfoTip;

  /// Success message after install
  ///
  /// In zh, this message translates to:
  /// **'Extension installed successfully'**
  String get extensionsInstalledSuccess;

  /// Setting - download provider order
  ///
  /// In zh, this message translates to:
  /// **'Download Priority'**
  String get extensionsDownloadPriority;

  /// Subtitle for download priority
  ///
  /// In zh, this message translates to:
  /// **'Set download service order'**
  String get extensionsDownloadPrioritySubtitle;

  /// Setting and page title for choosing which download extensions can be used during fallback
  ///
  /// In zh, this message translates to:
  /// **'Fallback Extensions'**
  String get extensionsFallbackTitle;

  /// Subtitle for download fallback extensions menu
  ///
  /// In zh, this message translates to:
  /// **'Choose which installed download extensions can be used as fallback'**
  String get extensionsFallbackSubtitle;

  /// Empty state - no download providers
  ///
  /// In zh, this message translates to:
  /// **'No extensions with download provider'**
  String get extensionsNoDownloadProvider;

  /// Setting - metadata provider order
  ///
  /// In zh, this message translates to:
  /// **'Metadata Priority'**
  String get extensionsMetadataPriority;

  /// Subtitle for metadata priority
  ///
  /// In zh, this message translates to:
  /// **'Set search & metadata source order'**
  String get extensionsMetadataPrioritySubtitle;

  /// Empty state - no metadata providers
  ///
  /// In zh, this message translates to:
  /// **'No extensions with metadata provider'**
  String get extensionsNoMetadataProvider;

  /// Setting - search provider selection
  ///
  /// In zh, this message translates to:
  /// **'Search Provider'**
  String get extensionsSearchProvider;

  /// Empty state - no search providers
  ///
  /// In zh, this message translates to:
  /// **'No extensions with custom search'**
  String get extensionsNoCustomSearch;

  /// Search provider setting description
  ///
  /// In zh, this message translates to:
  /// **'Choose which service to use for searching tracks'**
  String get extensionsSearchProviderDescription;

  /// Label for custom search provider
  ///
  /// In zh, this message translates to:
  /// **'Custom search'**
  String get extensionsCustomSearch;

  /// Error message when extension fails to load
  ///
  /// In zh, this message translates to:
  /// **'Error loading extension'**
  String get extensionsErrorLoading;

  /// Quality option - CD quality FLAC
  ///
  /// In zh, this message translates to:
  /// **'FLAC Lossless'**
  String get qualityFlacLossless;

  /// Technical spec for lossless
  ///
  /// In zh, this message translates to:
  /// **'16-bit / 44.1kHz'**
  String get qualityFlacLosslessSubtitle;

  /// Quality option - high resolution FLAC
  ///
  /// In zh, this message translates to:
  /// **'Hi-Res FLAC'**
  String get qualityHiResFlac;

  /// Technical spec for hi-res
  ///
  /// In zh, this message translates to:
  /// **'24-bit / up to 96kHz'**
  String get qualityHiResFlacSubtitle;

  /// Quality option - maximum resolution FLAC
  ///
  /// In zh, this message translates to:
  /// **'Hi-Res FLAC Max'**
  String get qualityHiResFlacMax;

  /// Technical spec for hi-res max
  ///
  /// In zh, this message translates to:
  /// **'24-bit / up to 192kHz'**
  String get qualityHiResFlacMaxSubtitle;

  /// Quality option label for Tidal lossy 320kbps
  ///
  /// In zh, this message translates to:
  /// **'Lossy 320kbps'**
  String get downloadLossy320;

  /// Setting title to pick output format for Tidal lossy downloads
  ///
  /// In zh, this message translates to:
  /// **'Lossy Format'**
  String get downloadLossyFormat;

  /// Title of the Tidal lossy format picker bottom sheet
  ///
  /// In zh, this message translates to:
  /// **'Lossy 320kbps Format'**
  String get downloadLossy320Format;

  /// Description in the Tidal lossy format picker
  ///
  /// In zh, this message translates to:
  /// **'Choose the output format for Tidal 320kbps lossy downloads. The original AAC stream will be converted to your selected format.'**
  String get downloadLossy320FormatDesc;

  /// Tidal lossy format option - MP3 320kbps
  ///
  /// In zh, this message translates to:
  /// **'MP3 320kbps'**
  String get downloadLossyMp3;

  /// Subtitle for MP3 320kbps Tidal lossy option
  ///
  /// In zh, this message translates to:
  /// **'Best compatibility, ~10MB per track'**
  String get downloadLossyMp3Subtitle;

  /// Tidal lossy format option - Opus 256kbps
  ///
  /// In zh, this message translates to:
  /// **'Opus 256kbps'**
  String get downloadLossyOpus256;

  /// Subtitle for Opus 256kbps Tidal lossy option
  ///
  /// In zh, this message translates to:
  /// **'Best quality Opus, ~8MB per track'**
  String get downloadLossyOpus256Subtitle;

  /// Tidal lossy format option - Opus 128kbps
  ///
  /// In zh, this message translates to:
  /// **'Opus 128kbps'**
  String get downloadLossyOpus128;

  /// Subtitle for Opus 128kbps Tidal lossy option
  ///
  /// In zh, this message translates to:
  /// **'Smallest size, ~4MB per track'**
  String get downloadLossyOpus128Subtitle;

  /// Note about quality availability
  ///
  /// In zh, this message translates to:
  /// **'Actual quality depends on track availability from the service'**
  String get qualityNote;

  /// Setting - show quality picker
  ///
  /// In zh, this message translates to:
  /// **'Ask Before Download'**
  String get downloadAskBeforeDownload;

  /// Setting - download folder
  ///
  /// In zh, this message translates to:
  /// **'Download Directory'**
  String get downloadDirectory;

  /// Setting - separate folder for singles
  ///
  /// In zh, this message translates to:
  /// **'Separate Singles Folder'**
  String get downloadSeparateSinglesFolder;

  /// Setting - album folder organization
  ///
  /// In zh, this message translates to:
  /// **'Album Folder Structure'**
  String get downloadAlbumFolderStructure;

  /// Setting - choose whether artist folders use Album Artist or Track Artist
  ///
  /// In zh, this message translates to:
  /// **'Use Album Artist for folders'**
  String get downloadUseAlbumArtistForFolders;

  /// Setting - strip featured artists from folder name
  ///
  /// In zh, this message translates to:
  /// **'Primary artist only for folders'**
  String get downloadUsePrimaryArtistOnly;

  /// Subtitle when primary artist only is enabled
  ///
  /// In zh, this message translates to:
  /// **'Featured artists removed from folder name (e.g. Justin Bieber, Quavo → Justin Bieber)'**
  String get downloadUsePrimaryArtistOnlyEnabled;

  /// Subtitle when primary artist only is disabled
  ///
  /// In zh, this message translates to:
  /// **'Full artist string used for folder name'**
  String get downloadUsePrimaryArtistOnlyDisabled;

  /// Dialog title - choose audio quality
  ///
  /// In zh, this message translates to:
  /// **'Select Quality'**
  String get downloadSelectQuality;

  /// Label - download source
  ///
  /// In zh, this message translates to:
  /// **'Download From'**
  String get downloadFrom;

  /// Theme option - pure black
  ///
  /// In zh, this message translates to:
  /// **'AMOLED Dark'**
  String get appearanceAmoledDark;

  /// Subtitle for AMOLED dark
  ///
  /// In zh, this message translates to:
  /// **'Pure black background'**
  String get appearanceAmoledDarkSubtitle;

  /// Button - clear all queue items
  ///
  /// In zh, this message translates to:
  /// **'Clear All'**
  String get queueClearAll;

  /// Clear queue confirmation
  ///
  /// In zh, this message translates to:
  /// **'Are you sure you want to clear all downloads?'**
  String get queueClearAllMessage;

  /// Setting toggle for auto-export
  ///
  /// In zh, this message translates to:
  /// **'Auto-export failed downloads'**
  String get settingsAutoExportFailed;

  /// Subtitle for auto-export setting
  ///
  /// In zh, this message translates to:
  /// **'Save failed downloads to TXT file automatically'**
  String get settingsAutoExportFailedSubtitle;

  /// Setting for network type preference
  ///
  /// In zh, this message translates to:
  /// **'Download Network'**
  String get settingsDownloadNetwork;

  /// Network option - use any connection
  ///
  /// In zh, this message translates to:
  /// **'WiFi + Mobile Data'**
  String get settingsDownloadNetworkAny;

  /// Network option - only use WiFi
  ///
  /// In zh, this message translates to:
  /// **'WiFi Only'**
  String get settingsDownloadNetworkWifiOnly;

  /// Subtitle explaining network preference
  ///
  /// In zh, this message translates to:
  /// **'Choose which network to use for downloads. When set to WiFi Only, downloads will pause on mobile data.'**
  String get settingsDownloadNetworkSubtitle;

  /// Album folder option
  ///
  /// In zh, this message translates to:
  /// **'Artist / Album'**
  String get albumFolderArtistAlbum;

  /// Folder structure example
  ///
  /// In zh, this message translates to:
  /// **'Albums/Artist Name/Album Name/'**
  String get albumFolderArtistAlbumSubtitle;

  /// Album folder option with year
  ///
  /// In zh, this message translates to:
  /// **'Artist / [Year] Album'**
  String get albumFolderArtistYearAlbum;

  /// Folder structure example
  ///
  /// In zh, this message translates to:
  /// **'Albums/Artist Name/[2005] Album Name/'**
  String get albumFolderArtistYearAlbumSubtitle;

  /// Album folder option
  ///
  /// In zh, this message translates to:
  /// **'Album Only'**
  String get albumFolderAlbumOnly;

  /// Folder structure example
  ///
  /// In zh, this message translates to:
  /// **'Albums/Album Name/'**
  String get albumFolderAlbumOnlySubtitle;

  /// Album folder option with year
  ///
  /// In zh, this message translates to:
  /// **'[Year] Album'**
  String get albumFolderYearAlbum;

  /// Folder structure example
  ///
  /// In zh, this message translates to:
  /// **'Albums/[2005] Album Name/'**
  String get albumFolderYearAlbumSubtitle;

  /// Album folder option with singles inside artist
  ///
  /// In zh, this message translates to:
  /// **'Artist / Album + Singles'**
  String get albumFolderArtistAlbumSingles;

  /// Folder structure example
  ///
  /// In zh, this message translates to:
  /// **'Artist/Album/ and Artist/Singles/'**
  String get albumFolderArtistAlbumSinglesSubtitle;

  /// Album folder option with singles directly in artist folder
  ///
  /// In zh, this message translates to:
  /// **'Artist / Album (Singles flat)'**
  String get albumFolderArtistAlbumFlat;

  /// Folder structure example for flat singles
  ///
  /// In zh, this message translates to:
  /// **'Artist/Album/ and Artist/song.flac'**
  String get albumFolderArtistAlbumFlatSubtitle;

  /// Button - delete selected tracks
  ///
  /// In zh, this message translates to:
  /// **'Delete Selected'**
  String get downloadedAlbumDeleteSelected;

  /// Delete confirmation with count
  ///
  /// In zh, this message translates to:
  /// **'Delete {count} {count, plural, =1{track} other{tracks}} from this album?\n\nThis will also delete the files from storage.'**
  String downloadedAlbumDeleteMessage(int count);

  /// Selection count indicator
  ///
  /// In zh, this message translates to:
  /// **'{count} selected'**
  String downloadedAlbumSelectedCount(int count);

  /// Status - all items selected
  ///
  /// In zh, this message translates to:
  /// **'All tracks selected'**
  String get downloadedAlbumAllSelected;

  /// Selection hint
  ///
  /// In zh, this message translates to:
  /// **'Tap tracks to select'**
  String get downloadedAlbumTapToSelect;

  /// Delete button text with count
  ///
  /// In zh, this message translates to:
  /// **'Delete {count} {count, plural, =1{track} other{tracks}}'**
  String downloadedAlbumDeleteCount(int count);

  /// Placeholder when nothing selected
  ///
  /// In zh, this message translates to:
  /// **'Select tracks to delete'**
  String get downloadedAlbumSelectToDelete;

  /// Header for disc separator in multi-disc albums
  ///
  /// In zh, this message translates to:
  /// **'Disc {discNumber}'**
  String downloadedAlbumDiscHeader(int discNumber);

  /// Recent access item type - artist
  ///
  /// In zh, this message translates to:
  /// **'Artist'**
  String get recentTypeArtist;

  /// Recent access item type - album
  ///
  /// In zh, this message translates to:
  /// **'Album'**
  String get recentTypeAlbum;

  /// Recent access item type - song/track
  ///
  /// In zh, this message translates to:
  /// **'Song'**
  String get recentTypeSong;

  /// Recent access item type - playlist
  ///
  /// In zh, this message translates to:
  /// **'Playlist'**
  String get recentTypePlaylist;

  /// Empty state text for recent access list
  ///
  /// In zh, this message translates to:
  /// **'No recent items yet'**
  String get recentEmpty;

  /// Button label to unhide hidden downloads in recent access
  ///
  /// In zh, this message translates to:
  /// **'Show All Downloads'**
  String get recentShowAllDownloads;

  /// Snackbar message when tapping playlist in recent access
  ///
  /// In zh, this message translates to:
  /// **'Playlist: {name}'**
  String recentPlaylistInfo(String name);

  /// Button - download artist discography
  ///
  /// In zh, this message translates to:
  /// **'Download Discography'**
  String get discographyDownload;

  /// Option - download entire discography
  ///
  /// In zh, this message translates to:
  /// **'Download All'**
  String get discographyDownloadAll;

  /// Subtitle showing total tracks and albums
  ///
  /// In zh, this message translates to:
  /// **'{count} tracks from {albumCount} releases'**
  String discographyDownloadAllSubtitle(int count, int albumCount);

  /// Option - download only albums
  ///
  /// In zh, this message translates to:
  /// **'Albums Only'**
  String get discographyAlbumsOnly;

  /// Subtitle showing album tracks count
  ///
  /// In zh, this message translates to:
  /// **'{count} tracks from {albumCount} albums'**
  String discographyAlbumsOnlySubtitle(int count, int albumCount);

  /// Option - download only singles
  ///
  /// In zh, this message translates to:
  /// **'Singles & EPs Only'**
  String get discographySinglesOnly;

  /// Subtitle showing singles tracks count
  ///
  /// In zh, this message translates to:
  /// **'{count} tracks from {albumCount} singles'**
  String discographySinglesOnlySubtitle(int count, int albumCount);

  /// Option - manually select albums to download
  ///
  /// In zh, this message translates to:
  /// **'Select Albums...'**
  String get discographySelectAlbums;

  /// Subtitle for select albums option
  ///
  /// In zh, this message translates to:
  /// **'Choose specific albums or singles'**
  String get discographySelectAlbumsSubtitle;

  /// Progress - fetching album tracks
  ///
  /// In zh, this message translates to:
  /// **'Fetching tracks...'**
  String get discographyFetchingTracks;

  /// Progress - fetching specific album
  ///
  /// In zh, this message translates to:
  /// **'Fetching {current} of {total}...'**
  String discographyFetchingAlbum(int current, int total);

  /// Selection count badge
  ///
  /// In zh, this message translates to:
  /// **'{count} selected'**
  String discographySelectedCount(int count);

  /// Button - download selected albums
  ///
  /// In zh, this message translates to:
  /// **'Download Selected'**
  String get discographyDownloadSelected;

  /// Snackbar - tracks added from discography
  ///
  /// In zh, this message translates to:
  /// **'Added {count} tracks to queue'**
  String discographyAddedToQueue(int count);

  /// Snackbar - with skipped tracks count
  ///
  /// In zh, this message translates to:
  /// **'{added} added, {skipped} already downloaded'**
  String discographySkippedDownloaded(int added, int skipped);

  /// Error - no albums found for artist
  ///
  /// In zh, this message translates to:
  /// **'No albums available'**
  String get discographyNoAlbums;

  /// Error - some albums failed to load
  ///
  /// In zh, this message translates to:
  /// **'Failed to fetch some albums'**
  String get discographyFailedToFetch;

  /// Section header for storage access settings
  ///
  /// In zh, this message translates to:
  /// **'Storage Access'**
  String get sectionStorageAccess;

  /// Toggle for MANAGE_EXTERNAL_STORAGE permission
  ///
  /// In zh, this message translates to:
  /// **'All Files Access'**
  String get allFilesAccess;

  /// Subtitle when all files access is enabled
  ///
  /// In zh, this message translates to:
  /// **'Can write to any folder'**
  String get allFilesAccessEnabledSubtitle;

  /// Subtitle when all files access is disabled
  ///
  /// In zh, this message translates to:
  /// **'Limited to media folders only'**
  String get allFilesAccessDisabledSubtitle;

  /// Description explaining when to enable all files access
  ///
  /// In zh, this message translates to:
  /// **'Enable this if you encounter write errors when saving to custom folders. Android 13+ restricts access to certain directories by default.'**
  String get allFilesAccessDescription;

  /// Message when permission is permanently denied
  ///
  /// In zh, this message translates to:
  /// **'Permission was denied. Please enable \'All files access\' manually in system settings.'**
  String get allFilesAccessDeniedMessage;

  /// Snackbar message when user disables all files access
  ///
  /// In zh, this message translates to:
  /// **'All Files Access disabled. The app will use limited storage access.'**
  String get allFilesAccessDisabledMessage;

  /// Settings menu item - local library
  ///
  /// In zh, this message translates to:
  /// **'Local Library'**
  String get settingsLocalLibrary;

  /// Subtitle for local library settings
  ///
  /// In zh, this message translates to:
  /// **'Scan music & detect duplicates'**
  String get settingsLocalLibrarySubtitle;

  /// Settings menu item - cache management
  ///
  /// In zh, this message translates to:
  /// **'Storage & Cache'**
  String get settingsCache;

  /// Subtitle for cache management menu
  ///
  /// In zh, this message translates to:
  /// **'View size and clear cached data'**
  String get settingsCacheSubtitle;

  /// Library settings page title
  ///
  /// In zh, this message translates to:
  /// **'Local Library'**
  String get libraryTitle;

  /// Section header for scan settings
  ///
  /// In zh, this message translates to:
  /// **'Scan Settings'**
  String get libraryScanSettings;

  /// Toggle to enable library scanning
  ///
  /// In zh, this message translates to:
  /// **'Enable Local Library'**
  String get libraryEnableLocalLibrary;

  /// Subtitle for enable toggle
  ///
  /// In zh, this message translates to:
  /// **'Scan and track your existing music'**
  String get libraryEnableLocalLibrarySubtitle;

  /// Folder selection setting
  ///
  /// In zh, this message translates to:
  /// **'Library Folder'**
  String get libraryFolder;

  /// Placeholder when no folder selected
  ///
  /// In zh, this message translates to:
  /// **'Tap to select folder'**
  String get libraryFolderHint;

  /// Toggle for duplicate indicator in search
  ///
  /// In zh, this message translates to:
  /// **'Show Duplicate Indicator'**
  String get libraryShowDuplicateIndicator;

  /// Subtitle for duplicate indicator toggle
  ///
  /// In zh, this message translates to:
  /// **'Show when searching for existing tracks'**
  String get libraryShowDuplicateIndicatorSubtitle;

  /// Setting for automatic library scanning
  ///
  /// In zh, this message translates to:
  /// **'Auto Scan'**
  String get libraryAutoScan;

  /// Subtitle for auto scan setting
  ///
  /// In zh, this message translates to:
  /// **'Automatically scan your library for new files'**
  String get libraryAutoScanSubtitle;

  /// Auto scan disabled
  ///
  /// In zh, this message translates to:
  /// **'Off'**
  String get libraryAutoScanOff;

  /// Auto scan when app opens
  ///
  /// In zh, this message translates to:
  /// **'Every app open'**
  String get libraryAutoScanOnOpen;

  /// Auto scan once per day
  ///
  /// In zh, this message translates to:
  /// **'Daily'**
  String get libraryAutoScanDaily;

  /// Auto scan once per week
  ///
  /// In zh, this message translates to:
  /// **'Weekly'**
  String get libraryAutoScanWeekly;

  /// Section header for library actions
  ///
  /// In zh, this message translates to:
  /// **'Actions'**
  String get libraryActions;

  /// Button to start library scan
  ///
  /// In zh, this message translates to:
  /// **'Scan Library'**
  String get libraryScan;

  /// Subtitle for scan button
  ///
  /// In zh, this message translates to:
  /// **'Scan for audio files'**
  String get libraryScanSubtitle;

  /// Message when trying to scan without folder
  ///
  /// In zh, this message translates to:
  /// **'Select a folder first'**
  String get libraryScanSelectFolderFirst;

  /// Button to remove entries for missing files
  ///
  /// In zh, this message translates to:
  /// **'Cleanup Missing Files'**
  String get libraryCleanupMissingFiles;

  /// Subtitle for cleanup button
  ///
  /// In zh, this message translates to:
  /// **'Remove entries for files that no longer exist'**
  String get libraryCleanupMissingFilesSubtitle;

  /// Button to clear all library entries
  ///
  /// In zh, this message translates to:
  /// **'Clear Library'**
  String get libraryClear;

  /// Subtitle for clear button
  ///
  /// In zh, this message translates to:
  /// **'Remove all scanned tracks'**
  String get libraryClearSubtitle;

  /// Dialog title for clear confirmation
  ///
  /// In zh, this message translates to:
  /// **'Clear Library'**
  String get libraryClearConfirmTitle;

  /// Dialog message for clear confirmation
  ///
  /// In zh, this message translates to:
  /// **'This will remove all scanned tracks from your library. Your actual music files will not be deleted.'**
  String get libraryClearConfirmMessage;

  /// Section header for about info
  ///
  /// In zh, this message translates to:
  /// **'About Local Library'**
  String get libraryAbout;

  /// Description of local library feature
  ///
  /// In zh, this message translates to:
  /// **'Scans your existing music collection to detect duplicates when downloading. Supports FLAC, M4A, MP3, Opus, and OGG formats. Metadata is read from file tags when available.'**
  String get libraryAboutDescription;

  /// Unit label for tracks count (without the number itself)
  ///
  /// In zh, this message translates to:
  /// **'{count, plural, =1{track} other{tracks}}'**
  String libraryTracksUnit(int count);

  /// Unit label for files count during library scanning
  ///
  /// In zh, this message translates to:
  /// **'{count, plural, =1{file} other{files}}'**
  String libraryFilesUnit(int count);

  /// Last scan time display
  ///
  /// In zh, this message translates to:
  /// **'Last scanned: {time}'**
  String libraryLastScanned(String time);

  /// Shown when library has never been scanned
  ///
  /// In zh, this message translates to:
  /// **'Never'**
  String get libraryLastScannedNever;

  /// Status during scan
  ///
  /// In zh, this message translates to:
  /// **'Scanning...'**
  String get libraryScanning;

  /// Status shown after file scanning finishes but library persistence is still running
  ///
  /// In zh, this message translates to:
  /// **'Finalizing library...'**
  String get libraryScanFinalizing;

  /// Scan progress display
  ///
  /// In zh, this message translates to:
  /// **'{progress}% of {total} files'**
  String libraryScanProgress(String progress, int total);

  /// Badge shown on tracks that exist in local library
  ///
  /// In zh, this message translates to:
  /// **'In Library'**
  String get libraryInLibrary;

  /// Snackbar after cleanup
  ///
  /// In zh, this message translates to:
  /// **'Removed {count} missing files from library'**
  String libraryRemovedMissingFiles(int count);

  /// Snackbar after clearing library
  ///
  /// In zh, this message translates to:
  /// **'Library cleared'**
  String get libraryCleared;

  /// Dialog title for storage permission
  ///
  /// In zh, this message translates to:
  /// **'Storage Access Required'**
  String get libraryStorageAccessRequired;

  /// Dialog message for storage permission
  ///
  /// In zh, this message translates to:
  /// **'SpotiFLAC needs storage access to scan your music library. Please grant permission in settings.'**
  String get libraryStorageAccessMessage;

  /// Error when folder doesn't exist
  ///
  /// In zh, this message translates to:
  /// **'Selected folder does not exist'**
  String get libraryFolderNotExist;

  /// Badge for tracks downloaded via SpotiFLAC
  ///
  /// In zh, this message translates to:
  /// **'Downloaded'**
  String get librarySourceDownloaded;

  /// Badge for tracks from local library scan
  ///
  /// In zh, this message translates to:
  /// **'Local'**
  String get librarySourceLocal;

  /// Filter chip - show all library items
  ///
  /// In zh, this message translates to:
  /// **'All'**
  String get libraryFilterAll;

  /// Filter chip - show only downloaded items
  ///
  /// In zh, this message translates to:
  /// **'Downloaded'**
  String get libraryFilterDownloaded;

  /// Filter chip - show only local library items
  ///
  /// In zh, this message translates to:
  /// **'Local'**
  String get libraryFilterLocal;

  /// Filter bottom sheet title
  ///
  /// In zh, this message translates to:
  /// **'Filters'**
  String get libraryFilterTitle;

  /// Reset all filters button
  ///
  /// In zh, this message translates to:
  /// **'Reset'**
  String get libraryFilterReset;

  /// Apply filters button
  ///
  /// In zh, this message translates to:
  /// **'Apply'**
  String get libraryFilterApply;

  /// Filter section - source type
  ///
  /// In zh, this message translates to:
  /// **'Source'**
  String get libraryFilterSource;

  /// Filter section - audio quality
  ///
  /// In zh, this message translates to:
  /// **'Quality'**
  String get libraryFilterQuality;

  /// Filter option - high resolution audio
  ///
  /// In zh, this message translates to:
  /// **'Hi-Res (24bit)'**
  String get libraryFilterQualityHiRes;

  /// Filter option - CD quality audio
  ///
  /// In zh, this message translates to:
  /// **'CD (16bit)'**
  String get libraryFilterQualityCD;

  /// Filter option - lossy compressed audio
  ///
  /// In zh, this message translates to:
  /// **'Lossy'**
  String get libraryFilterQualityLossy;

  /// Filter section - file format
  ///
  /// In zh, this message translates to:
  /// **'Format'**
  String get libraryFilterFormat;

  /// Filter section - metadata completeness
  ///
  /// In zh, this message translates to:
  /// **'Metadata'**
  String get libraryFilterMetadata;

  /// Filter option - items with complete metadata
  ///
  /// In zh, this message translates to:
  /// **'Complete metadata'**
  String get libraryFilterMetadataComplete;

  /// Filter option - items missing any tracked metadata field
  ///
  /// In zh, this message translates to:
  /// **'Missing any metadata'**
  String get libraryFilterMetadataMissingAny;

  /// Filter option - items missing release year/date
  ///
  /// In zh, this message translates to:
  /// **'Missing year'**
  String get libraryFilterMetadataMissingYear;

  /// Filter option - items missing genre
  ///
  /// In zh, this message translates to:
  /// **'Missing genre'**
  String get libraryFilterMetadataMissingGenre;

  /// Filter option - items missing album artist
  ///
  /// In zh, this message translates to:
  /// **'Missing album artist'**
  String get libraryFilterMetadataMissingAlbumArtist;

  /// Filter section - sort order
  ///
  /// In zh, this message translates to:
  /// **'Sort'**
  String get libraryFilterSort;

  /// Sort option - newest first
  ///
  /// In zh, this message translates to:
  /// **'Latest'**
  String get libraryFilterSortLatest;

  /// Sort option - oldest first
  ///
  /// In zh, this message translates to:
  /// **'Oldest'**
  String get libraryFilterSortOldest;

  /// Sort option - album ascending
  ///
  /// In zh, this message translates to:
  /// **'Album (A-Z)'**
  String get libraryFilterSortAlbumAsc;

  /// Sort option - album descending
  ///
  /// In zh, this message translates to:
  /// **'Album (Z-A)'**
  String get libraryFilterSortAlbumDesc;

  /// Sort option - genre ascending
  ///
  /// In zh, this message translates to:
  /// **'Genre (A-Z)'**
  String get libraryFilterSortGenreAsc;

  /// Sort option - genre descending
  ///
  /// In zh, this message translates to:
  /// **'Genre (Z-A)'**
  String get libraryFilterSortGenreDesc;

  /// Relative time - less than a minute ago
  ///
  /// In zh, this message translates to:
  /// **'Just now'**
  String get timeJustNow;

  /// Relative time - minutes ago
  ///
  /// In zh, this message translates to:
  /// **'{count, plural, =1{1 minute ago} other{{count} minutes ago}}'**
  String timeMinutesAgo(int count);

  /// Relative time - hours ago
  ///
  /// In zh, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String timeHoursAgo(int count);

  /// Tutorial welcome page title
  ///
  /// In zh, this message translates to:
  /// **'Welcome to SpotiFLAC!'**
  String get tutorialWelcomeTitle;

  /// Tutorial welcome page description
  ///
  /// In zh, this message translates to:
  /// **'Let\'s learn how to download your favorite music in lossless quality. This quick tutorial will show you the basics.'**
  String get tutorialWelcomeDesc;

  /// Tutorial welcome tip 1
  ///
  /// In zh, this message translates to:
  /// **'Download music from Spotify, Deezer, or paste any supported URL'**
  String get tutorialWelcomeTip1;

  /// Tutorial welcome tip 2
  ///
  /// In zh, this message translates to:
  /// **'Get FLAC quality audio from Tidal, Qobuz, or Deezer'**
  String get tutorialWelcomeTip2;

  /// Tutorial welcome tip 3
  ///
  /// In zh, this message translates to:
  /// **'Automatic metadata, cover art, and lyrics embedding'**
  String get tutorialWelcomeTip3;

  /// Tutorial search page title
  ///
  /// In zh, this message translates to:
  /// **'Finding Music'**
  String get tutorialSearchTitle;

  /// Tutorial search page description
  ///
  /// In zh, this message translates to:
  /// **'There are two easy ways to find music you want to download.'**
  String get tutorialSearchDesc;

  /// Tutorial download page title
  ///
  /// In zh, this message translates to:
  /// **'Downloading Music'**
  String get tutorialDownloadTitle;

  /// Tutorial download page description
  ///
  /// In zh, this message translates to:
  /// **'Downloading music is simple and fast. Here\'s how it works.'**
  String get tutorialDownloadDesc;

  /// Tutorial library page title
  ///
  /// In zh, this message translates to:
  /// **'Your Library'**
  String get tutorialLibraryTitle;

  /// Tutorial library page description
  ///
  /// In zh, this message translates to:
  /// **'All your downloaded music is organized in the Library tab.'**
  String get tutorialLibraryDesc;

  /// Tutorial library tip 1
  ///
  /// In zh, this message translates to:
  /// **'View download progress and queue in the Library tab'**
  String get tutorialLibraryTip1;

  /// Tutorial library tip 2
  ///
  /// In zh, this message translates to:
  /// **'Tap any track to play it with your music player'**
  String get tutorialLibraryTip2;

  /// Tutorial library tip 3
  ///
  /// In zh, this message translates to:
  /// **'Switch between list and grid view for better browsing'**
  String get tutorialLibraryTip3;

  /// Tutorial extensions page title
  ///
  /// In zh, this message translates to:
  /// **'Extensions'**
  String get tutorialExtensionsTitle;

  /// Tutorial extensions page description
  ///
  /// In zh, this message translates to:
  /// **'Extend the app\'s capabilities with community extensions.'**
  String get tutorialExtensionsDesc;

  /// Tutorial extensions tip 1
  ///
  /// In zh, this message translates to:
  /// **'Browse the Repo tab to discover useful extensions'**
  String get tutorialExtensionsTip1;

  /// Tutorial extensions tip 2
  ///
  /// In zh, this message translates to:
  /// **'Add new download providers or search sources'**
  String get tutorialExtensionsTip2;

  /// Tutorial extensions tip 3
  ///
  /// In zh, this message translates to:
  /// **'Get lyrics, enhanced metadata, and more features'**
  String get tutorialExtensionsTip3;

  /// Tutorial settings page title
  ///
  /// In zh, this message translates to:
  /// **'Customize Your Experience'**
  String get tutorialSettingsTitle;

  /// Tutorial settings page description
  ///
  /// In zh, this message translates to:
  /// **'Personalize the app in Settings to match your preferences.'**
  String get tutorialSettingsDesc;

  /// Tutorial settings tip 1
  ///
  /// In zh, this message translates to:
  /// **'Change download location and folder organization'**
  String get tutorialSettingsTip1;

  /// Tutorial settings tip 2
  ///
  /// In zh, this message translates to:
  /// **'Set default audio quality and format preferences'**
  String get tutorialSettingsTip2;

  /// Tutorial settings tip 3
  ///
  /// In zh, this message translates to:
  /// **'Customize app theme and appearance'**
  String get tutorialSettingsTip3;

  /// Tutorial completion message
  ///
  /// In zh, this message translates to:
  /// **'You\'re all set! Start downloading your favorite music now.'**
  String get tutorialReadyMessage;

  /// Button to force a complete rescan of library
  ///
  /// In zh, this message translates to:
  /// **'Force Full Scan'**
  String get libraryForceFullScan;

  /// Subtitle for force full scan button
  ///
  /// In zh, this message translates to:
  /// **'Rescan all files, ignoring cache'**
  String get libraryForceFullScanSubtitle;

  /// Button to remove history entries for deleted files
  ///
  /// In zh, this message translates to:
  /// **'Cleanup Orphaned Downloads'**
  String get cleanupOrphanedDownloads;

  /// Subtitle for orphaned cleanup button
  ///
  /// In zh, this message translates to:
  /// **'Remove history entries for files that no longer exist'**
  String get cleanupOrphanedDownloadsSubtitle;

  /// Snackbar after orphan cleanup
  ///
  /// In zh, this message translates to:
  /// **'Removed {count} orphaned entries from history'**
  String cleanupOrphanedDownloadsResult(int count);

  /// Snackbar when no orphans found
  ///
  /// In zh, this message translates to:
  /// **'No orphaned entries found'**
  String get cleanupOrphanedDownloadsNone;

  /// Cache management page title
  ///
  /// In zh, this message translates to:
  /// **'Storage & Cache'**
  String get cacheTitle;

  /// Heading for cache summary card
  ///
  /// In zh, this message translates to:
  /// **'Cache overview'**
  String get cacheSummaryTitle;

  /// Helper text for cache summary card
  ///
  /// In zh, this message translates to:
  /// **'Clearing cache will not remove downloaded music files.'**
  String get cacheSummarySubtitle;

  /// Total cache size shown in summary
  ///
  /// In zh, this message translates to:
  /// **'Estimated cache usage: {size}'**
  String cacheEstimatedTotal(String size);

  /// Section header for cache entries
  ///
  /// In zh, this message translates to:
  /// **'Cached Data'**
  String get cacheSectionStorage;

  /// Section header for cleanup actions
  ///
  /// In zh, this message translates to:
  /// **'Maintenance'**
  String get cacheSectionMaintenance;

  /// Cache item title for app cache directory
  ///
  /// In zh, this message translates to:
  /// **'App cache directory'**
  String get cacheAppDirectory;

  /// Description of what app cache directory contains
  ///
  /// In zh, this message translates to:
  /// **'HTTP responses, WebView data, and other temporary app data.'**
  String get cacheAppDirectoryDesc;

  /// Cache item title for temporary files directory
  ///
  /// In zh, this message translates to:
  /// **'Temporary directory'**
  String get cacheTempDirectory;

  /// Description of what temporary directory contains
  ///
  /// In zh, this message translates to:
  /// **'Temporary files from downloads and audio conversion.'**
  String get cacheTempDirectoryDesc;

  /// Cache item title for persistent cover images
  ///
  /// In zh, this message translates to:
  /// **'Cover image cache'**
  String get cacheCoverImage;

  /// Description of what cover image cache contains
  ///
  /// In zh, this message translates to:
  /// **'Downloaded album and track cover art. Will re-download when viewed.'**
  String get cacheCoverImageDesc;

  /// Cache item title for local library cover art images
  ///
  /// In zh, this message translates to:
  /// **'Library cover cache'**
  String get cacheLibraryCover;

  /// Description of what library cover cache contains
  ///
  /// In zh, this message translates to:
  /// **'Cover art extracted from local music files. Will re-extract on next scan.'**
  String get cacheLibraryCoverDesc;

  /// Cache item title for explore home feed cache
  ///
  /// In zh, this message translates to:
  /// **'Explore feed cache'**
  String get cacheExploreFeed;

  /// Description of what explore feed cache contains
  ///
  /// In zh, this message translates to:
  /// **'Explore tab content (new releases, trending). Will refresh on next visit.'**
  String get cacheExploreFeedDesc;

  /// Cache item title for track ID lookup cache
  ///
  /// In zh, this message translates to:
  /// **'Track lookup cache'**
  String get cacheTrackLookup;

  /// Description of what track lookup cache contains
  ///
  /// In zh, this message translates to:
  /// **'Spotify/Deezer track ID lookups. Clearing may slow next few searches.'**
  String get cacheTrackLookupDesc;

  /// Description of what cleanup unused data does
  ///
  /// In zh, this message translates to:
  /// **'Remove orphaned download history and library entries for missing files.'**
  String get cacheCleanupUnusedDesc;

  /// Label when cache category has no data
  ///
  /// In zh, this message translates to:
  /// **'No cached data'**
  String get cacheNoData;

  /// Cache size and file count
  ///
  /// In zh, this message translates to:
  /// **'{size} in {count} files'**
  String cacheSizeWithFiles(String size, int count);

  /// Cache size only
  ///
  /// In zh, this message translates to:
  /// **'{size}'**
  String cacheSizeOnly(String size);

  /// Track cache entry count
  ///
  /// In zh, this message translates to:
  /// **'{count} entries'**
  String cacheEntries(int count);

  /// Snackbar after clearing selected cache
  ///
  /// In zh, this message translates to:
  /// **'Cleared: {target}'**
  String cacheClearSuccess(String target);

  /// Dialog title before clearing one cache category
  ///
  /// In zh, this message translates to:
  /// **'Clear cache?'**
  String get cacheClearConfirmTitle;

  /// Dialog message before clearing selected cache
  ///
  /// In zh, this message translates to:
  /// **'This will clear cached data for {target}. Downloaded music files will not be deleted.'**
  String cacheClearConfirmMessage(String target);

  /// Dialog title before clearing all caches
  ///
  /// In zh, this message translates to:
  /// **'Clear all cache?'**
  String get cacheClearAllConfirmTitle;

  /// Dialog message before clearing all caches
  ///
  /// In zh, this message translates to:
  /// **'This will clear all cache categories on this page. Downloaded music files will not be deleted.'**
  String get cacheClearAllConfirmMessage;

  /// Button label to clear all caches
  ///
  /// In zh, this message translates to:
  /// **'Clear all cache'**
  String get cacheClearAll;

  /// Action title for cleaning unused entries
  ///
  /// In zh, this message translates to:
  /// **'Cleanup unused data'**
  String get cacheCleanupUnused;

  /// Subtitle for cleanup unused data action
  ///
  /// In zh, this message translates to:
  /// **'Remove orphaned download history and missing library entries'**
  String get cacheCleanupUnusedSubtitle;

  /// Snackbar after unused data cleanup
  ///
  /// In zh, this message translates to:
  /// **'Cleanup completed: {downloadCount} orphaned downloads, {libraryCount} missing library entries'**
  String cacheCleanupResult(int downloadCount, int libraryCount);

  /// Button label to refresh cache statistics
  ///
  /// In zh, this message translates to:
  /// **'Refresh stats'**
  String get cacheRefreshStats;

  /// Menu action - save album cover art as file
  ///
  /// In zh, this message translates to:
  /// **'Save Cover Art'**
  String get trackSaveCoverArt;

  /// Subtitle for save cover art action
  ///
  /// In zh, this message translates to:
  /// **'Save album art as .jpg file'**
  String get trackSaveCoverArtSubtitle;

  /// Menu action - save lyrics as .lrc file
  ///
  /// In zh, this message translates to:
  /// **'Save Lyrics (.lrc)'**
  String get trackSaveLyrics;

  /// Subtitle for save lyrics action
  ///
  /// In zh, this message translates to:
  /// **'Fetch and save lyrics as .lrc file'**
  String get trackSaveLyricsSubtitle;

  /// Snackbar while saving lyrics to file
  ///
  /// In zh, this message translates to:
  /// **'Saving lyrics...'**
  String get trackSaveLyricsProgress;

  /// Menu action - re-embed metadata into audio file
  ///
  /// In zh, this message translates to:
  /// **'Re-enrich'**
  String get trackReEnrich;

  /// Subtitle for re-enrich metadata action for local items
  ///
  /// In zh, this message translates to:
  /// **'Search metadata online and embed into file'**
  String get trackReEnrichOnlineSubtitle;

  /// Section title for field selection in re-enrich dialog
  ///
  /// In zh, this message translates to:
  /// **'Fields to update'**
  String get trackReEnrichFieldsTitle;

  /// Checkbox label for cover art field in re-enrich
  ///
  /// In zh, this message translates to:
  /// **'Cover Art'**
  String get trackReEnrichFieldCover;

  /// Checkbox label for lyrics field in re-enrich
  ///
  /// In zh, this message translates to:
  /// **'Lyrics'**
  String get trackReEnrichFieldLyrics;

  /// Checkbox label for basic tags in re-enrich (title/artist are never overwritten)
  ///
  /// In zh, this message translates to:
  /// **'Album, Album Artist'**
  String get trackReEnrichFieldBasicTags;

  /// Checkbox label for track info in re-enrich
  ///
  /// In zh, this message translates to:
  /// **'Track & Disc Number'**
  String get trackReEnrichFieldTrackInfo;

  /// Checkbox label for release info in re-enrich
  ///
  /// In zh, this message translates to:
  /// **'Date & ISRC'**
  String get trackReEnrichFieldReleaseInfo;

  /// Checkbox label for extra metadata in re-enrich
  ///
  /// In zh, this message translates to:
  /// **'Genre, Label, Copyright'**
  String get trackReEnrichFieldExtra;

  /// Select all fields checkbox in re-enrich
  ///
  /// In zh, this message translates to:
  /// **'Select All'**
  String get trackReEnrichSelectAll;

  /// Menu action - edit embedded metadata
  ///
  /// In zh, this message translates to:
  /// **'Edit Metadata'**
  String get trackEditMetadata;

  /// Snackbar after cover art saved
  ///
  /// In zh, this message translates to:
  /// **'Cover art saved to {fileName}'**
  String trackCoverSaved(String fileName);

  /// Snackbar when no cover art URL or embedded cover
  ///
  /// In zh, this message translates to:
  /// **'No cover art source available'**
  String get trackCoverNoSource;

  /// Snackbar after lyrics saved
  ///
  /// In zh, this message translates to:
  /// **'Lyrics saved to {fileName}'**
  String trackLyricsSaved(String fileName);

  /// Snackbar while re-enriching metadata
  ///
  /// In zh, this message translates to:
  /// **'Re-enriching metadata...'**
  String get trackReEnrichProgress;

  /// Snackbar while searching metadata from internet for local items
  ///
  /// In zh, this message translates to:
  /// **'Searching metadata online...'**
  String get trackReEnrichSearching;

  /// Snackbar after successful re-enrichment
  ///
  /// In zh, this message translates to:
  /// **'Metadata re-enriched successfully'**
  String get trackReEnrichSuccess;

  /// Snackbar when FFmpeg embed fails for MP3/Opus
  ///
  /// In zh, this message translates to:
  /// **'FFmpeg metadata embed failed'**
  String get trackReEnrichFfmpegFailed;

  /// Action/button label for queueing FLAC redownloads for local tracks
  ///
  /// In zh, this message translates to:
  /// **'Queue FLAC'**
  String get queueFlacAction;

  /// Confirmation dialog body before queueing FLAC redownloads for local tracks
  ///
  /// In zh, this message translates to:
  /// **'Search online matches for the selected tracks and queue FLAC downloads.\n\nExisting files will not be modified or deleted.\n\nOnly high-confidence matches are queued automatically.\n\n{count} selected'**
  String queueFlacConfirmMessage(int count);

  /// Snackbar while resolving remote matches for local FLAC redownloads
  ///
  /// In zh, this message translates to:
  /// **'Finding FLAC matches... ({current}/{total})'**
  String queueFlacFindingProgress(int current, int total);

  /// Snackbar when no safe FLAC redownload matches were found
  ///
  /// In zh, this message translates to:
  /// **'No reliable online matches found for the selection'**
  String get queueFlacNoReliableMatches;

  /// Snackbar when some selected local tracks were queued for FLAC redownload and some were skipped
  ///
  /// In zh, this message translates to:
  /// **'Added {addedCount} tracks to queue, skipped {skippedCount}'**
  String queueFlacQueuedWithSkipped(int addedCount, int skippedCount);

  /// Snackbar when save operation fails
  ///
  /// In zh, this message translates to:
  /// **'Failed: {error}'**
  String trackSaveFailed(String error);

  /// Menu item - convert audio format
  ///
  /// In zh, this message translates to:
  /// **'Convert Format'**
  String get trackConvertFormat;

  /// Subtitle for convert format menu item
  ///
  /// In zh, this message translates to:
  /// **'Convert to MP3, Opus, ALAC, or FLAC'**
  String get trackConvertFormatSubtitle;

  /// Title of convert bottom sheet
  ///
  /// In zh, this message translates to:
  /// **'Convert Audio'**
  String get trackConvertTitle;

  /// Label for format selection
  ///
  /// In zh, this message translates to:
  /// **'Target Format'**
  String get trackConvertTargetFormat;

  /// Label for bitrate selection
  ///
  /// In zh, this message translates to:
  /// **'Bitrate'**
  String get trackConvertBitrate;

  /// Confirmation dialog title
  ///
  /// In zh, this message translates to:
  /// **'Confirm Conversion'**
  String get trackConvertConfirmTitle;

  /// Confirmation dialog message
  ///
  /// In zh, this message translates to:
  /// **'Convert from {sourceFormat} to {targetFormat} at {bitrate}?\n\nThe original file will be deleted after conversion.'**
  String trackConvertConfirmMessage(
    String sourceFormat,
    String targetFormat,
    String bitrate,
  );

  /// Confirmation dialog message for lossless-to-lossless conversion
  ///
  /// In zh, this message translates to:
  /// **'Convert from {sourceFormat} to {targetFormat}? (Lossless — no quality loss)\n\nThe original file will be deleted after conversion.'**
  String trackConvertConfirmMessageLossless(
    String sourceFormat,
    String targetFormat,
  );

  /// Hint shown when converting between lossless formats
  ///
  /// In zh, this message translates to:
  /// **'Lossless conversion — no quality loss'**
  String get trackConvertLosslessHint;

  /// Snackbar while converting
  ///
  /// In zh, this message translates to:
  /// **'Converting audio...'**
  String get trackConvertConverting;

  /// Snackbar after successful conversion
  ///
  /// In zh, this message translates to:
  /// **'Converted to {format} successfully'**
  String trackConvertSuccess(String format);

  /// Snackbar when conversion fails
  ///
  /// In zh, this message translates to:
  /// **'Conversion failed'**
  String get trackConvertFailed;

  /// Title for CUE split bottom sheet
  ///
  /// In zh, this message translates to:
  /// **'Split CUE Sheet'**
  String get cueSplitTitle;

  /// Subtitle for CUE split menu item
  ///
  /// In zh, this message translates to:
  /// **'Split CUE+FLAC into individual tracks'**
  String get cueSplitSubtitle;

  /// Album name in CUE split sheet
  ///
  /// In zh, this message translates to:
  /// **'Album: {album}'**
  String cueSplitAlbum(String album);

  /// Artist name in CUE split sheet
  ///
  /// In zh, this message translates to:
  /// **'Artist: {artist}'**
  String cueSplitArtist(String artist);

  /// Number of tracks in CUE sheet
  ///
  /// In zh, this message translates to:
  /// **'{count} tracks'**
  String cueSplitTrackCount(int count);

  /// CUE split confirmation dialog title
  ///
  /// In zh, this message translates to:
  /// **'Split CUE Album'**
  String get cueSplitConfirmTitle;

  /// CUE split confirmation dialog message
  ///
  /// In zh, this message translates to:
  /// **'Split \"{album}\" into {count} individual FLAC files?\n\nFiles will be saved to the same directory.'**
  String cueSplitConfirmMessage(String album, int count);

  /// Snackbar while splitting CUE
  ///
  /// In zh, this message translates to:
  /// **'Splitting CUE sheet... ({current}/{total})'**
  String cueSplitSplitting(int current, int total);

  /// Snackbar after successful CUE split
  ///
  /// In zh, this message translates to:
  /// **'Split into {count} tracks successfully'**
  String cueSplitSuccess(int count);

  /// Snackbar when CUE split fails
  ///
  /// In zh, this message translates to:
  /// **'CUE split failed'**
  String get cueSplitFailed;

  /// Error when CUE audio file is missing
  ///
  /// In zh, this message translates to:
  /// **'Audio file not found for this CUE sheet'**
  String get cueSplitNoAudioFile;

  /// Button text to start CUE splitting
  ///
  /// In zh, this message translates to:
  /// **'Split into Tracks'**
  String get cueSplitButton;

  /// Generic action button - create
  ///
  /// In zh, this message translates to:
  /// **'Create'**
  String get actionCreate;

  /// Library section title for custom folders
  ///
  /// In zh, this message translates to:
  /// **'My folders'**
  String get collectionFoldersTitle;

  /// Custom folder for saved tracks to download later
  ///
  /// In zh, this message translates to:
  /// **'Wishlist'**
  String get collectionWishlist;

  /// Custom folder for favorite tracks
  ///
  /// In zh, this message translates to:
  /// **'Loved'**
  String get collectionLoved;

  /// Custom user playlists folder
  ///
  /// In zh, this message translates to:
  /// **'Playlists'**
  String get collectionPlaylists;

  /// Single playlist label
  ///
  /// In zh, this message translates to:
  /// **'Playlist'**
  String get collectionPlaylist;

  /// Action to add a track to user playlist
  ///
  /// In zh, this message translates to:
  /// **'Add to playlist'**
  String get collectionAddToPlaylist;

  /// Action to create a new playlist
  ///
  /// In zh, this message translates to:
  /// **'Create playlist'**
  String get collectionCreatePlaylist;

  /// Empty state title when user has no playlists
  ///
  /// In zh, this message translates to:
  /// **'No playlists yet'**
  String get collectionNoPlaylistsYet;

  /// Empty state subtitle when user has no playlists
  ///
  /// In zh, this message translates to:
  /// **'Create a playlist to start categorizing tracks'**
  String get collectionNoPlaylistsSubtitle;

  /// Track count label for custom playlists
  ///
  /// In zh, this message translates to:
  /// **'{count, plural, =1{1 track} other{{count} tracks}}'**
  String collectionPlaylistTracks(int count);

  /// Snackbar after adding track to playlist
  ///
  /// In zh, this message translates to:
  /// **'Added to \"{playlistName}\"'**
  String collectionAddedToPlaylist(String playlistName);

  /// Snackbar when track already exists in playlist
  ///
  /// In zh, this message translates to:
  /// **'Already in \"{playlistName}\"'**
  String collectionAlreadyInPlaylist(String playlistName);

  /// Snackbar after creating playlist
  ///
  /// In zh, this message translates to:
  /// **'Playlist created'**
  String get collectionPlaylistCreated;

  /// Hint text for playlist name input
  ///
  /// In zh, this message translates to:
  /// **'Playlist name'**
  String get collectionPlaylistNameHint;

  /// Validation error for empty playlist name
  ///
  /// In zh, this message translates to:
  /// **'Playlist name is required'**
  String get collectionPlaylistNameRequired;

  /// Action to rename playlist
  ///
  /// In zh, this message translates to:
  /// **'Rename playlist'**
  String get collectionRenamePlaylist;

  /// Action to delete playlist
  ///
  /// In zh, this message translates to:
  /// **'Delete playlist'**
  String get collectionDeletePlaylist;

  /// Confirmation message for deleting playlist
  ///
  /// In zh, this message translates to:
  /// **'Delete \"{playlistName}\" and all tracks inside it?'**
  String collectionDeletePlaylistMessage(String playlistName);

  /// Snackbar after deleting playlist
  ///
  /// In zh, this message translates to:
  /// **'Playlist deleted'**
  String get collectionPlaylistDeleted;

  /// Snackbar after renaming playlist
  ///
  /// In zh, this message translates to:
  /// **'Playlist renamed'**
  String get collectionPlaylistRenamed;

  /// Wishlist empty state title
  ///
  /// In zh, this message translates to:
  /// **'Wishlist is empty'**
  String get collectionWishlistEmptyTitle;

  /// Wishlist empty state subtitle
  ///
  /// In zh, this message translates to:
  /// **'Tap + on tracks to save what you want to download later'**
  String get collectionWishlistEmptySubtitle;

  /// Loved empty state title
  ///
  /// In zh, this message translates to:
  /// **'Loved folder is empty'**
  String get collectionLovedEmptyTitle;

  /// Loved empty state subtitle
  ///
  /// In zh, this message translates to:
  /// **'Tap love on tracks to keep your favorites'**
  String get collectionLovedEmptySubtitle;

  /// Playlist empty state title
  ///
  /// In zh, this message translates to:
  /// **'Playlist is empty'**
  String get collectionPlaylistEmptyTitle;

  /// Playlist empty state subtitle
  ///
  /// In zh, this message translates to:
  /// **'Long-press + on any track to add it here'**
  String get collectionPlaylistEmptySubtitle;

  /// Tooltip for removing track from playlist
  ///
  /// In zh, this message translates to:
  /// **'Remove from playlist'**
  String get collectionRemoveFromPlaylist;

  /// Tooltip for removing track from wishlist/loved folder
  ///
  /// In zh, this message translates to:
  /// **'Remove from folder'**
  String get collectionRemoveFromFolder;

  /// Snackbar after removing a track from a collection
  ///
  /// In zh, this message translates to:
  /// **'\"{trackName}\" removed'**
  String collectionRemoved(String trackName);

  /// Snackbar after adding track to loved folder
  ///
  /// In zh, this message translates to:
  /// **'\"{trackName}\" added to Loved'**
  String collectionAddedToLoved(String trackName);

  /// Snackbar after removing track from loved folder
  ///
  /// In zh, this message translates to:
  /// **'\"{trackName}\" removed from Loved'**
  String collectionRemovedFromLoved(String trackName);

  /// Snackbar after adding track to wishlist
  ///
  /// In zh, this message translates to:
  /// **'\"{trackName}\" added to Wishlist'**
  String collectionAddedToWishlist(String trackName);

  /// Snackbar after removing track from wishlist
  ///
  /// In zh, this message translates to:
  /// **'\"{trackName}\" removed from Wishlist'**
  String collectionRemovedFromWishlist(String trackName);

  /// Bottom sheet action label - add track to loved folder
  ///
  /// In zh, this message translates to:
  /// **'Add to Loved'**
  String get trackOptionAddToLoved;

  /// Bottom sheet action label - remove track from loved folder
  ///
  /// In zh, this message translates to:
  /// **'Remove from Loved'**
  String get trackOptionRemoveFromLoved;

  /// Bottom sheet action label - add track to wishlist
  ///
  /// In zh, this message translates to:
  /// **'Add to Wishlist'**
  String get trackOptionAddToWishlist;

  /// Bottom sheet action label - remove track from wishlist
  ///
  /// In zh, this message translates to:
  /// **'Remove from Wishlist'**
  String get trackOptionRemoveFromWishlist;

  /// Bottom sheet action to pick a custom cover image for a playlist
  ///
  /// In zh, this message translates to:
  /// **'Change cover image'**
  String get collectionPlaylistChangeCover;

  /// Bottom sheet action to remove custom cover image from a playlist
  ///
  /// In zh, this message translates to:
  /// **'Remove cover image'**
  String get collectionPlaylistRemoveCover;

  /// Share button text with count in selection mode
  ///
  /// In zh, this message translates to:
  /// **'Share {count} {count, plural, =1{track} other{tracks}}'**
  String selectionShareCount(int count);

  /// Snackbar when no selected files exist on disk
  ///
  /// In zh, this message translates to:
  /// **'No shareable files found'**
  String get selectionShareNoFiles;

  /// Convert button text with count in selection mode
  ///
  /// In zh, this message translates to:
  /// **'Convert {count} {count, plural, =1{track} other{tracks}}'**
  String selectionConvertCount(int count);

  /// Snackbar when no selected tracks support conversion
  ///
  /// In zh, this message translates to:
  /// **'No convertible tracks selected'**
  String get selectionConvertNoConvertible;

  /// Confirmation dialog title for batch conversion
  ///
  /// In zh, this message translates to:
  /// **'Batch Convert'**
  String get selectionBatchConvertConfirmTitle;

  /// Confirmation dialog message for batch conversion
  ///
  /// In zh, this message translates to:
  /// **'Convert {count} {count, plural, =1{track} other{tracks}} to {format} at {bitrate}?\n\nOriginal files will be deleted after conversion.'**
  String selectionBatchConvertConfirmMessage(
    int count,
    String format,
    String bitrate,
  );

  /// Confirmation dialog message for lossless batch conversion
  ///
  /// In zh, this message translates to:
  /// **'Convert {count} {count, plural, =1{track} other{tracks}} to {format}? (Lossless — no quality loss)\n\nOriginal files will be deleted after conversion.'**
  String selectionBatchConvertConfirmMessageLossless(int count, String format);

  /// Snackbar during batch conversion progress
  ///
  /// In zh, this message translates to:
  /// **'Converting {current} of {total}...'**
  String selectionBatchConvertProgress(int current, int total);

  /// Snackbar after batch conversion completes
  ///
  /// In zh, this message translates to:
  /// **'Converted {success} of {total} tracks to {format}'**
  String selectionBatchConvertSuccess(int success, int total, String format);

  /// Downloaded tracks count badge
  ///
  /// In zh, this message translates to:
  /// **'{count} downloaded'**
  String downloadedAlbumDownloadedCount(int count);

  /// Subtitle when Album Artist is used for folder naming
  ///
  /// In zh, this message translates to:
  /// **'Artist folders use Album Artist when available'**
  String get downloadUseAlbumArtistForFoldersAlbumSubtitle;

  /// Subtitle when Track Artist is used for folder naming
  ///
  /// In zh, this message translates to:
  /// **'Artist folders use Track Artist only'**
  String get downloadUseAlbumArtistForFoldersTrackSubtitle;

  /// Title for the lyrics provider priority page
  ///
  /// In zh, this message translates to:
  /// **'Lyrics Providers'**
  String get lyricsProvidersTitle;

  /// Description on the lyrics provider priority page
  ///
  /// In zh, this message translates to:
  /// **'Enable, disable and reorder lyrics sources. Providers are tried top-to-bottom until lyrics are found.'**
  String get lyricsProvidersDescription;

  /// Info tip on lyrics provider priority page
  ///
  /// In zh, this message translates to:
  /// **'Extension lyrics providers always run before built-in providers. At least one provider must remain enabled.'**
  String get lyricsProvidersInfoText;

  /// Section header for enabled providers
  ///
  /// In zh, this message translates to:
  /// **'Enabled ({count})'**
  String lyricsProvidersEnabledSection(int count);

  /// Section header for disabled providers
  ///
  /// In zh, this message translates to:
  /// **'Disabled ({count})'**
  String lyricsProvidersDisabledSection(int count);

  /// Snackbar when user tries to disable the last enabled provider
  ///
  /// In zh, this message translates to:
  /// **'At least one provider must remain enabled'**
  String get lyricsProvidersAtLeastOne;

  /// Snackbar after saving lyrics provider priority
  ///
  /// In zh, this message translates to:
  /// **'Lyrics provider priority saved'**
  String get lyricsProvidersSaved;

  /// Body text of the discard-changes dialog on lyrics provider page
  ///
  /// In zh, this message translates to:
  /// **'You have unsaved changes that will be lost.'**
  String get lyricsProvidersDiscardContent;

  /// Description for LRCLIB provider
  ///
  /// In zh, this message translates to:
  /// **'Open-source synced lyrics database'**
  String get lyricsProviderLrclibDesc;

  /// Description for Netease provider
  ///
  /// In zh, this message translates to:
  /// **'NetEase Cloud Music (good for Asian songs)'**
  String get lyricsProviderNeteaseDesc;

  /// Description for Musixmatch provider
  ///
  /// In zh, this message translates to:
  /// **'Largest lyrics database (multi-language)'**
  String get lyricsProviderMusixmatchDesc;

  /// Description for Apple Music provider
  ///
  /// In zh, this message translates to:
  /// **'Word-by-word synced lyrics (via proxy)'**
  String get lyricsProviderAppleMusicDesc;

  /// Description for QQ Music provider
  ///
  /// In zh, this message translates to:
  /// **'QQ Music (good for Chinese songs, via proxy)'**
  String get lyricsProviderQqMusicDesc;

  /// Generic description for extension-based lyrics providers
  ///
  /// In zh, this message translates to:
  /// **'Extension provider'**
  String get lyricsProviderExtensionDesc;

  /// Title of SAF migration dialog
  ///
  /// In zh, this message translates to:
  /// **'Storage Update Required'**
  String get safMigrationTitle;

  /// First paragraph of SAF migration dialog
  ///
  /// In zh, this message translates to:
  /// **'SpotiFLAC now uses Android Storage Access Framework (SAF) for downloads. This fixes \"permission denied\" errors on Android 10+.'**
  String get safMigrationMessage1;

  /// Second paragraph of SAF migration dialog
  ///
  /// In zh, this message translates to:
  /// **'Please select your download folder again to switch to the new storage system.'**
  String get safMigrationMessage2;

  /// Snackbar after successfully migrating to SAF
  ///
  /// In zh, this message translates to:
  /// **'Download folder updated to SAF mode'**
  String get safMigrationSuccess;

  /// Settings menu item - donate
  ///
  /// In zh, this message translates to:
  /// **'Donate'**
  String get settingsDonate;

  /// Subtitle for donate menu item
  ///
  /// In zh, this message translates to:
  /// **'Support SpotiFLAC-Mobile development'**
  String get settingsDonateSubtitle;

  /// Tooltip for the Love All button on album/playlist screens
  ///
  /// In zh, this message translates to:
  /// **'Love All'**
  String get tooltipLoveAll;

  /// Tooltip for the Add to Playlist button
  ///
  /// In zh, this message translates to:
  /// **'Add to Playlist'**
  String get tooltipAddToPlaylist;

  /// Snackbar after removing multiple tracks from Loved folder
  ///
  /// In zh, this message translates to:
  /// **'Removed {count} tracks from Loved'**
  String snackbarRemovedTracksFromLoved(int count);

  /// Snackbar after adding multiple tracks to Loved folder
  ///
  /// In zh, this message translates to:
  /// **'Added {count} tracks to Loved'**
  String snackbarAddedTracksToLoved(int count);

  /// Dialog title for bulk download confirmation
  ///
  /// In zh, this message translates to:
  /// **'Download All'**
  String get dialogDownloadAllTitle;

  /// Body of the Download All confirmation dialog
  ///
  /// In zh, this message translates to:
  /// **'Download {count} tracks?'**
  String dialogDownloadAllMessage(int count);

  /// Checkbox label in import dialog to skip already-downloaded songs
  ///
  /// In zh, this message translates to:
  /// **'Skip already downloaded songs'**
  String get homeSkipAlreadyDownloaded;

  /// Context menu item to navigate to the album page
  ///
  /// In zh, this message translates to:
  /// **'Go to Album'**
  String get homeGoToAlbum;

  /// Snackbar when album info cannot be loaded
  ///
  /// In zh, this message translates to:
  /// **'Album info not available'**
  String get homeAlbumInfoUnavailable;

  /// Snackbar while loading a CUE sheet file
  ///
  /// In zh, this message translates to:
  /// **'Loading CUE sheet...'**
  String get snackbarLoadingCueSheet;

  /// Snackbar after successfully saving track metadata
  ///
  /// In zh, this message translates to:
  /// **'Metadata saved successfully'**
  String get snackbarMetadataSaved;

  /// Snackbar when lyrics embedding fails
  ///
  /// In zh, this message translates to:
  /// **'Failed to embed lyrics'**
  String get snackbarFailedToEmbedLyrics;

  /// Snackbar when writing metadata back to file fails
  ///
  /// In zh, this message translates to:
  /// **'Failed to write back to storage'**
  String get snackbarFailedToWriteStorage;

  /// Generic error snackbar with error detail
  ///
  /// In zh, this message translates to:
  /// **'Error: {error}'**
  String snackbarError(String error);

  /// Snackbar when an extension button has no action configured
  ///
  /// In zh, this message translates to:
  /// **'No action defined for this button'**
  String get snackbarNoActionDefined;

  /// Empty state message when an album has no tracks
  ///
  /// In zh, this message translates to:
  /// **'No tracks found for this album'**
  String get noTracksFoundForAlbum;

  /// Subtitle text in Android download location bottom sheet
  ///
  /// In zh, this message translates to:
  /// **'Choose storage mode for downloaded files.'**
  String get downloadLocationSubtitle;

  /// Storage mode option - use legacy app folder
  ///
  /// In zh, this message translates to:
  /// **'App folder (non-SAF)'**
  String get storageModeAppFolder;

  /// Subtitle for app folder storage mode
  ///
  /// In zh, this message translates to:
  /// **'Use default Music/SpotiFLAC path'**
  String get storageModeAppFolderSubtitle;

  /// Storage mode option - use Android SAF picker
  ///
  /// In zh, this message translates to:
  /// **'SAF folder'**
  String get storageModeSaf;

  /// Subtitle for SAF storage mode
  ///
  /// In zh, this message translates to:
  /// **'Pick folder via Android Storage Access Framework'**
  String get storageModeSafSubtitle;

  /// Description text in filename format bottom sheet
  ///
  /// In zh, this message translates to:
  /// **'Customize how your files are named.'**
  String get downloadFilenameDescription;

  /// Label above filename tag chips
  ///
  /// In zh, this message translates to:
  /// **'Tap to insert tag:'**
  String get downloadFilenameInsertTag;

  /// Subtitle when separate singles folder is enabled
  ///
  /// In zh, this message translates to:
  /// **'Albums/ and Singles/ folders'**
  String get downloadSeparateSinglesEnabled;

  /// Subtitle when separate singles folder is disabled
  ///
  /// In zh, this message translates to:
  /// **'All files in same structure'**
  String get downloadSeparateSinglesDisabled;

  /// Setting title for artist folder filter options
  ///
  /// In zh, this message translates to:
  /// **'Artist Name Filters'**
  String get downloadArtistNameFilters;

  /// Setting title for adding a playlist folder prefix before the normal organization structure
  ///
  /// In zh, this message translates to:
  /// **'Create playlist source folder'**
  String get downloadCreatePlaylistSourceFolder;

  /// Subtitle when playlist source folder prefix is enabled
  ///
  /// In zh, this message translates to:
  /// **'Playlist downloads use Playlist/ plus your normal folder structure.'**
  String get downloadCreatePlaylistSourceFolderEnabled;

  /// Subtitle when playlist source folder prefix is disabled
  ///
  /// In zh, this message translates to:
  /// **'Playlist downloads use the normal folder structure only.'**
  String get downloadCreatePlaylistSourceFolderDisabled;

  /// Subtitle when playlist folder prefix setting is redundant because folder organization is already by playlist
  ///
  /// In zh, this message translates to:
  /// **'By Playlist already places downloads inside a playlist folder.'**
  String get downloadCreatePlaylistSourceFolderRedundant;

  /// Setting title for SongLink country region
  ///
  /// In zh, this message translates to:
  /// **'SongLink Region'**
  String get downloadSongLinkRegion;

  /// Setting title for network compatibility toggle
  ///
  /// In zh, this message translates to:
  /// **'Network compatibility mode'**
  String get downloadNetworkCompatibilityMode;

  /// Subtitle when network compatibility mode is enabled
  ///
  /// In zh, this message translates to:
  /// **'Enabled: try HTTP + accept invalid TLS certificates (unsafe)'**
  String get downloadNetworkCompatibilityModeEnabled;

  /// Subtitle when network compatibility mode is disabled
  ///
  /// In zh, this message translates to:
  /// **'Off: strict HTTPS certificate validation (recommended)'**
  String get downloadNetworkCompatibilityModeDisabled;

  /// Hint shown instead of Ask-quality subtitle when no built-in service selected
  ///
  /// In zh, this message translates to:
  /// **'Select a built-in service to enable'**
  String get downloadSelectServiceToEnable;

  /// Info hint when non-Tidal/Qobuz service is selected
  ///
  /// In zh, this message translates to:
  /// **'Select Tidal or Qobuz above to configure quality'**
  String get downloadSelectTidalQobuz;

  /// Subtitle for Embed Lyrics when Embed Metadata is disabled
  ///
  /// In zh, this message translates to:
  /// **'Disabled while Embed Metadata is turned off'**
  String get downloadEmbedLyricsDisabled;

  /// Toggle title for including Netease translated lyrics
  ///
  /// In zh, this message translates to:
  /// **'Netease: Include Translation'**
  String get downloadNeteaseIncludeTranslation;

  /// Subtitle when Netease translation is enabled
  ///
  /// In zh, this message translates to:
  /// **'Append translated lyrics when available'**
  String get downloadNeteaseIncludeTranslationEnabled;

  /// Subtitle when Netease translation is disabled
  ///
  /// In zh, this message translates to:
  /// **'Use original lyrics only'**
  String get downloadNeteaseIncludeTranslationDisabled;

  /// Toggle title for including Netease romanized lyrics
  ///
  /// In zh, this message translates to:
  /// **'Netease: Include Romanization'**
  String get downloadNeteaseIncludeRomanization;

  /// Subtitle when Netease romanization is enabled
  ///
  /// In zh, this message translates to:
  /// **'Append romanized lyrics when available'**
  String get downloadNeteaseIncludeRomanizationEnabled;

  /// Subtitle when Netease romanization is disabled
  ///
  /// In zh, this message translates to:
  /// **'Disabled'**
  String get downloadNeteaseIncludeRomanizationDisabled;

  /// Toggle title for Apple/QQ multi-person word-by-word lyrics
  ///
  /// In zh, this message translates to:
  /// **'Apple/QQ Multi-Person Word-by-Word'**
  String get downloadAppleQqMultiPerson;

  /// Subtitle when multi-person word-by-word is enabled
  ///
  /// In zh, this message translates to:
  /// **'Enable v1/v2 speaker and [bg:] tags'**
  String get downloadAppleQqMultiPersonEnabled;

  /// Subtitle when multi-person word-by-word is disabled
  ///
  /// In zh, this message translates to:
  /// **'Simplified word-by-word formatting'**
  String get downloadAppleQqMultiPersonDisabled;

  /// Setting title for Musixmatch language preference
  ///
  /// In zh, this message translates to:
  /// **'Musixmatch Language'**
  String get downloadMusixmatchLanguage;

  /// Option label when Musixmatch uses original language
  ///
  /// In zh, this message translates to:
  /// **'Auto (original)'**
  String get downloadMusixmatchLanguageAuto;

  /// Toggle title for filtering contributing artists in Album Artist metadata
  ///
  /// In zh, this message translates to:
  /// **'Filter contributing artists in Album Artist'**
  String get downloadFilterContributing;

  /// Subtitle when contributing artist filter is enabled
  ///
  /// In zh, this message translates to:
  /// **'Album Artist metadata uses primary artist only'**
  String get downloadFilterContributingEnabled;

  /// Subtitle when contributing artist filter is disabled
  ///
  /// In zh, this message translates to:
  /// **'Keep full Album Artist metadata value'**
  String get downloadFilterContributingDisabled;

  /// Subtitle for lyrics providers setting when no providers are enabled
  ///
  /// In zh, this message translates to:
  /// **'None enabled'**
  String get downloadProvidersNoneEnabled;

  /// Label for the Musixmatch language code text field
  ///
  /// In zh, this message translates to:
  /// **'Language code'**
  String get downloadMusixmatchLanguageCode;

  /// Hint text for the Musixmatch language code field
  ///
  /// In zh, this message translates to:
  /// **'auto / en / es / ja'**
  String get downloadMusixmatchLanguageHint;

  /// Description in the Musixmatch language picker
  ///
  /// In zh, this message translates to:
  /// **'Set preferred language code (example: en, es, ja). Leave empty for auto.'**
  String get downloadMusixmatchLanguageDesc;

  /// Button to reset Musixmatch language to automatic
  ///
  /// In zh, this message translates to:
  /// **'Auto'**
  String get downloadMusixmatchAuto;

  /// Subtitle for 'Any' network mode option
  ///
  /// In zh, this message translates to:
  /// **'WiFi + Mobile Data'**
  String get downloadNetworkAnySubtitle;

  /// Subtitle for 'WiFi only' network mode option
  ///
  /// In zh, this message translates to:
  /// **'Pause downloads on mobile data'**
  String get downloadNetworkWifiOnlySubtitle;

  /// Description in the SongLink region picker
  ///
  /// In zh, this message translates to:
  /// **'Used as userCountry for SongLink API lookup.'**
  String get downloadSongLinkRegionDesc;

  /// Snackbar when the audio format is not supported for the requested operation
  ///
  /// In zh, this message translates to:
  /// **'Unsupported audio format'**
  String get snackbarUnsupportedAudioFormat;

  /// Tooltip for refresh button on cache management page
  ///
  /// In zh, this message translates to:
  /// **'Refresh'**
  String get cacheRefresh;

  /// Dialog message for bulk playlist download confirmation
  ///
  /// In zh, this message translates to:
  /// **'Download {trackCount} {trackCount, plural, =1{track} other{tracks}} from {playlistCount} {playlistCount, plural, =1{playlist} other{playlists}}?'**
  String dialogDownloadPlaylistsMessage(int trackCount, int playlistCount);

  /// Button label for bulk downloading selected playlists
  ///
  /// In zh, this message translates to:
  /// **'Download {count} {count, plural, =1{playlist} other{playlists}}'**
  String bulkDownloadPlaylistsButton(int count);

  /// Button label when no playlists are selected for download
  ///
  /// In zh, this message translates to:
  /// **'Select playlists to download'**
  String get bulkDownloadSelectPlaylists;

  /// Snackbar when selected playlists contain no tracks
  ///
  /// In zh, this message translates to:
  /// **'Selected playlists have no tracks'**
  String get snackbarSelectedPlaylistsEmpty;

  /// Playlist count display
  ///
  /// In zh, this message translates to:
  /// **'{count, plural, =1{1 playlist} other{{count} playlists}}'**
  String playlistsCount(int count);

  /// Section title for selective online metadata auto-fill in the edit metadata sheet
  ///
  /// In zh, this message translates to:
  /// **'Auto-fill from online'**
  String get editMetadataAutoFill;

  /// Description for the auto-fill section
  ///
  /// In zh, this message translates to:
  /// **'Select fields to fill automatically from online metadata'**
  String get editMetadataAutoFillDesc;

  /// Button label to fetch online metadata and fill selected fields
  ///
  /// In zh, this message translates to:
  /// **'Fetch & Fill'**
  String get editMetadataAutoFillFetch;

  /// Snackbar shown while searching for online metadata
  ///
  /// In zh, this message translates to:
  /// **'Searching online...'**
  String get editMetadataAutoFillSearching;

  /// Snackbar when online metadata search returns no results
  ///
  /// In zh, this message translates to:
  /// **'No matching metadata found online'**
  String get editMetadataAutoFillNoResults;

  /// Snackbar confirming how many fields were auto-filled
  ///
  /// In zh, this message translates to:
  /// **'Filled {count} {count, plural, =1{field} other{fields}} from online metadata'**
  String editMetadataAutoFillDone(int count);

  /// Snackbar when user taps Fetch without selecting any fields
  ///
  /// In zh, this message translates to:
  /// **'Select at least one field to auto-fill'**
  String get editMetadataAutoFillNoneSelected;

  /// Chip label for title field in auto-fill selector
  ///
  /// In zh, this message translates to:
  /// **'Title'**
  String get editMetadataFieldTitle;

  /// Chip label for artist field in auto-fill selector
  ///
  /// In zh, this message translates to:
  /// **'Artist'**
  String get editMetadataFieldArtist;

  /// Chip label for album field in auto-fill selector
  ///
  /// In zh, this message translates to:
  /// **'Album'**
  String get editMetadataFieldAlbum;

  /// Chip label for album artist field in auto-fill selector
  ///
  /// In zh, this message translates to:
  /// **'Album Artist'**
  String get editMetadataFieldAlbumArtist;

  /// Chip label for date field in auto-fill selector
  ///
  /// In zh, this message translates to:
  /// **'Date'**
  String get editMetadataFieldDate;

  /// Chip label for track number field in auto-fill selector
  ///
  /// In zh, this message translates to:
  /// **'Track #'**
  String get editMetadataFieldTrackNum;

  /// Chip label for disc number field in auto-fill selector
  ///
  /// In zh, this message translates to:
  /// **'Disc #'**
  String get editMetadataFieldDiscNum;

  /// Chip label for genre field in auto-fill selector
  ///
  /// In zh, this message translates to:
  /// **'Genre'**
  String get editMetadataFieldGenre;

  /// Chip label for ISRC field in auto-fill selector
  ///
  /// In zh, this message translates to:
  /// **'ISRC'**
  String get editMetadataFieldIsrc;

  /// Chip label for label field in auto-fill selector
  ///
  /// In zh, this message translates to:
  /// **'Label'**
  String get editMetadataFieldLabel;

  /// Chip label for copyright field in auto-fill selector
  ///
  /// In zh, this message translates to:
  /// **'Copyright'**
  String get editMetadataFieldCopyright;

  /// Chip label for cover art field in auto-fill selector
  ///
  /// In zh, this message translates to:
  /// **'Cover Art'**
  String get editMetadataFieldCover;

  /// Button to select all fields for auto-fill
  ///
  /// In zh, this message translates to:
  /// **'All'**
  String get editMetadataSelectAll;

  /// Button to select only fields that are currently empty
  ///
  /// In zh, this message translates to:
  /// **'Empty only'**
  String get editMetadataSelectEmpty;

  /// Header for active downloads section with count
  ///
  /// In zh, this message translates to:
  /// **'Downloading ({count})'**
  String queueDownloadingCount(int count);

  /// Header label for downloaded items section in library
  ///
  /// In zh, this message translates to:
  /// **'Downloaded'**
  String get queueDownloadedHeader;

  /// Shown while filter results are being computed
  ///
  /// In zh, this message translates to:
  /// **'Filtering...'**
  String get queueFilteringIndicator;

  /// Track count label with plural support
  ///
  /// In zh, this message translates to:
  /// **'{count, plural, =1{1 track} other{{count} tracks}}'**
  String queueTrackCount(int count);

  /// Album count label with plural support
  ///
  /// In zh, this message translates to:
  /// **'{count, plural, =1{1 album} other{{count} albums}}'**
  String queueAlbumCount(int count);

  /// Empty state title when no album downloads exist
  ///
  /// In zh, this message translates to:
  /// **'No album downloads'**
  String get queueEmptyAlbums;

  /// Empty state subtitle for album downloads
  ///
  /// In zh, this message translates to:
  /// **'Download multiple tracks from an album to see them here'**
  String get queueEmptyAlbumsSubtitle;

  /// Empty state title when no single track downloads exist
  ///
  /// In zh, this message translates to:
  /// **'No single downloads'**
  String get queueEmptySingles;

  /// Empty state subtitle for single track downloads
  ///
  /// In zh, this message translates to:
  /// **'Single track downloads will appear here'**
  String get queueEmptySinglesSubtitle;

  /// Empty state title when download history is empty
  ///
  /// In zh, this message translates to:
  /// **'No download history'**
  String get queueEmptyHistory;

  /// Empty state subtitle for download history
  ///
  /// In zh, this message translates to:
  /// **'Downloaded tracks will appear here'**
  String get queueEmptyHistorySubtitle;

  /// Shown when all playlists are selected in selection mode
  ///
  /// In zh, this message translates to:
  /// **'All playlists selected'**
  String get selectionAllPlaylistsSelected;

  /// Hint shown in playlist selection mode
  ///
  /// In zh, this message translates to:
  /// **'Tap playlists to select'**
  String get selectionTapPlaylistsToSelect;

  /// Hint shown when no playlists are selected for deletion
  ///
  /// In zh, this message translates to:
  /// **'Select playlists to delete'**
  String get selectionSelectPlaylistsToDelete;

  /// Title for audio analysis section
  ///
  /// In zh, this message translates to:
  /// **'Audio Quality Analysis'**
  String get audioAnalysisTitle;

  /// Description for audio analysis tap-to-analyze prompt
  ///
  /// In zh, this message translates to:
  /// **'Verify lossless quality with spectrum analysis'**
  String get audioAnalysisDescription;

  /// Loading text while analyzing audio
  ///
  /// In zh, this message translates to:
  /// **'Analyzing audio...'**
  String get audioAnalysisAnalyzing;

  /// Sample rate metric label
  ///
  /// In zh, this message translates to:
  /// **'Sample Rate'**
  String get audioAnalysisSampleRate;

  /// Bit depth metric label
  ///
  /// In zh, this message translates to:
  /// **'Bit Depth'**
  String get audioAnalysisBitDepth;

  /// Channels metric label
  ///
  /// In zh, this message translates to:
  /// **'Channels'**
  String get audioAnalysisChannels;

  /// Duration metric label
  ///
  /// In zh, this message translates to:
  /// **'Duration'**
  String get audioAnalysisDuration;

  /// Nyquist frequency metric label
  ///
  /// In zh, this message translates to:
  /// **'Nyquist'**
  String get audioAnalysisNyquist;

  /// File size metric label
  ///
  /// In zh, this message translates to:
  /// **'Size'**
  String get audioAnalysisFileSize;

  /// Dynamic range metric label
  ///
  /// In zh, this message translates to:
  /// **'Dynamic Range'**
  String get audioAnalysisDynamicRange;

  /// Peak amplitude metric label
  ///
  /// In zh, this message translates to:
  /// **'Peak'**
  String get audioAnalysisPeak;

  /// RMS level metric label
  ///
  /// In zh, this message translates to:
  /// **'RMS'**
  String get audioAnalysisRms;

  /// Total samples metric label
  ///
  /// In zh, this message translates to:
  /// **'Samples'**
  String get audioAnalysisSamples;

  /// Extensions page - subtitle for built-in search provider option
  ///
  /// In zh, this message translates to:
  /// **'Search with {providerName}'**
  String extensionsSearchWith(String providerName);

  /// Extensions page - label for home feed provider selector
  ///
  /// In zh, this message translates to:
  /// **'Home Feed Provider'**
  String get extensionsHomeFeedProvider;

  /// Extensions page - description for home feed provider picker
  ///
  /// In zh, this message translates to:
  /// **'Choose which extension provides the home feed on the main screen'**
  String get extensionsHomeFeedDescription;

  /// Extensions page - home feed provider option: auto
  ///
  /// In zh, this message translates to:
  /// **'Auto'**
  String get extensionsHomeFeedAuto;

  /// Extensions page - subtitle for auto home feed option
  ///
  /// In zh, this message translates to:
  /// **'Automatically select the best available'**
  String get extensionsHomeFeedAutoSubtitle;

  /// Extensions page - subtitle for a specific extension home feed option
  ///
  /// In zh, this message translates to:
  /// **'Use {extensionName} home feed'**
  String extensionsHomeFeedUse(String extensionName);

  /// Extensions page - shown when no installed extension has home feed
  ///
  /// In zh, this message translates to:
  /// **'No extensions with home feed'**
  String get extensionsNoHomeFeedExtensions;

  /// Sort option - alphabetical ascending
  ///
  /// In zh, this message translates to:
  /// **'A-Z'**
  String get sortAlphaAsc;

  /// Sort option - alphabetical descending
  ///
  /// In zh, this message translates to:
  /// **'Z-A'**
  String get sortAlphaDesc;

  /// Dialog title when confirming cancellation of an active download
  ///
  /// In zh, this message translates to:
  /// **'Cancel download?'**
  String get cancelDownloadTitle;

  /// Dialog body when confirming cancellation of an active download
  ///
  /// In zh, this message translates to:
  /// **'This will cancel the active download for \"{trackName}\".'**
  String cancelDownloadContent(String trackName);

  /// Dialog button - keep the active download (do not cancel)
  ///
  /// In zh, this message translates to:
  /// **'Keep'**
  String get cancelDownloadKeep;

  /// Snackbar error when FFmpeg fails to write metadata
  ///
  /// In zh, this message translates to:
  /// **'Failed to save metadata via FFmpeg'**
  String get metadataSaveFailedFfmpeg;

  /// Snackbar error when writing metadata file back to storage fails
  ///
  /// In zh, this message translates to:
  /// **'Failed to write metadata back to storage'**
  String get metadataSaveFailedStorage;

  /// Snackbar shown when folder picker fails to open
  ///
  /// In zh, this message translates to:
  /// **'Failed to open folder picker: {error}'**
  String snackbarFolderPickerFailed(String error);

  /// Error state shown when album fails to load
  ///
  /// In zh, this message translates to:
  /// **'Failed to load album'**
  String get errorLoadAlbum;

  /// Error state shown when playlist fails to load
  ///
  /// In zh, this message translates to:
  /// **'Failed to load playlist'**
  String get errorLoadPlaylist;

  /// Error state shown when artist fails to load
  ///
  /// In zh, this message translates to:
  /// **'Failed to load artist'**
  String get errorLoadArtist;

  /// Android notification channel name for download progress
  ///
  /// In zh, this message translates to:
  /// **'Download Progress'**
  String get notifChannelDownloadName;

  /// Android notification channel description for download progress
  ///
  /// In zh, this message translates to:
  /// **'Shows download progress for tracks'**
  String get notifChannelDownloadDesc;

  /// Android notification channel name for library scan
  ///
  /// In zh, this message translates to:
  /// **'Library Scan'**
  String get notifChannelLibraryScanName;

  /// Android notification channel description for library scan
  ///
  /// In zh, this message translates to:
  /// **'Shows local library scan progress'**
  String get notifChannelLibraryScanDesc;

  /// Notification title while downloading a track
  ///
  /// In zh, this message translates to:
  /// **'Downloading {trackName}'**
  String notifDownloadingTrack(String trackName);

  /// Notification title while finalizing (embedding metadata) a track
  ///
  /// In zh, this message translates to:
  /// **'Finalizing {trackName}'**
  String notifFinalizingTrack(String trackName);

  /// Notification body while embedding metadata into a downloaded track
  ///
  /// In zh, this message translates to:
  /// **'Embedding metadata...'**
  String get notifEmbeddingMetadata;

  /// Notification title when track is already in library, with count
  ///
  /// In zh, this message translates to:
  /// **'Already in Library ({completed}/{total})'**
  String notifAlreadyInLibraryCount(int completed, int total);

  /// Notification title when track is already in library
  ///
  /// In zh, this message translates to:
  /// **'Already in Library'**
  String get notifAlreadyInLibrary;

  /// Notification title when download is complete, with count
  ///
  /// In zh, this message translates to:
  /// **'Download Complete ({completed}/{total})'**
  String notifDownloadCompleteCount(int completed, int total);

  /// Notification title when a single download is complete
  ///
  /// In zh, this message translates to:
  /// **'Download Complete'**
  String get notifDownloadComplete;

  /// Notification title when queue finishes with some failures
  ///
  /// In zh, this message translates to:
  /// **'Downloads Finished ({completed} done, {failed} failed)'**
  String notifDownloadsFinished(int completed, int failed);

  /// Notification title when all downloads finish successfully
  ///
  /// In zh, this message translates to:
  /// **'All Downloads Complete'**
  String get notifAllDownloadsComplete;

  /// Notification body for queue complete - how many tracks were downloaded
  ///
  /// In zh, this message translates to:
  /// **'{count} tracks downloaded successfully'**
  String notifTracksDownloadedSuccess(int count);

  /// Notification title while scanning local library
  ///
  /// In zh, this message translates to:
  /// **'Scanning local library'**
  String get notifScanningLibrary;

  /// Notification body for library scan progress when total is known
  ///
  /// In zh, this message translates to:
  /// **'{scanned}/{total} files • {percentage}%'**
  String notifLibraryScanProgressWithTotal(
    int scanned,
    int total,
    int percentage,
  );

  /// Notification body for library scan progress when total is unknown
  ///
  /// In zh, this message translates to:
  /// **'{scanned} files scanned • {percentage}%'**
  String notifLibraryScanProgressNoTotal(int scanned, int percentage);

  /// Notification title when library scan finishes
  ///
  /// In zh, this message translates to:
  /// **'Library scan complete'**
  String get notifLibraryScanComplete;

  /// Notification body for library scan complete - number of indexed tracks
  ///
  /// In zh, this message translates to:
  /// **'{count} tracks indexed'**
  String notifLibraryScanCompleteBody(int count);

  /// Library scan complete suffix - excluded track count
  ///
  /// In zh, this message translates to:
  /// **'{count} excluded'**
  String notifLibraryScanExcluded(int count);

  /// Library scan complete suffix - error count
  ///
  /// In zh, this message translates to:
  /// **'{count} errors'**
  String notifLibraryScanErrors(int count);

  /// Notification title when library scan fails
  ///
  /// In zh, this message translates to:
  /// **'Library scan failed'**
  String get notifLibraryScanFailed;

  /// Notification title when library scan is cancelled by the user
  ///
  /// In zh, this message translates to:
  /// **'Library scan cancelled'**
  String get notifLibraryScanCancelled;

  /// Notification body when library scan is cancelled
  ///
  /// In zh, this message translates to:
  /// **'Scan stopped before completion.'**
  String get notifLibraryScanStopped;

  /// Notification title while downloading an app update
  ///
  /// In zh, this message translates to:
  /// **'Downloading SpotiFLAC v{version}'**
  String notifDownloadingUpdate(String version);

  /// Notification body showing update download progress
  ///
  /// In zh, this message translates to:
  /// **'{received} / {total} MB • {percentage}%'**
  String notifUpdateProgress(String received, String total, int percentage);

  /// Notification title when app update download is complete
  ///
  /// In zh, this message translates to:
  /// **'Update Ready'**
  String get notifUpdateReady;

  /// Notification body when app update is ready to install
  ///
  /// In zh, this message translates to:
  /// **'SpotiFLAC v{version} downloaded. Tap to install.'**
  String notifUpdateReadyBody(String version);

  /// Notification title when app update download fails
  ///
  /// In zh, this message translates to:
  /// **'Update Failed'**
  String get notifUpdateFailed;

  /// Notification body when app update download fails
  ///
  /// In zh, this message translates to:
  /// **'Could not download update. Try again later.'**
  String get notifUpdateFailedBody;
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
      <String>['zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
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
