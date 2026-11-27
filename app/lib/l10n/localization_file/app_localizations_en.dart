// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get searchResultTypeAll => 'All';

  @override
  String get searchResultTypeVideo => 'Video';

  @override
  String get searchResultTypeChannel => 'Channels';

  @override
  String get searchResultTypeLive => 'Live';

  @override
  String get searchResultTypePlaylist => 'Playlists';

  @override
  String get navSettings => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsGroupPlayback => 'Playback & appearance';

  @override
  String get settingsGroupLibrary => 'Library & notifications';

  @override
  String get settingsGroupDiscovery => 'Discovery & channel';

  @override
  String get settingsGroupOther => 'More';

  @override
  String get settingsPlayer => 'Player';

  @override
  String get playerDefaultQuality => 'Default video quality';

  @override
  String get playerDefaultQualitySubtitle =>
      'Preferred quality when opening the player';

  @override
  String get playerDefaultSpeed => 'Default playback speed';

  @override
  String get playerDefaultSpeedSubtitle =>
      'Preferred playback speed when opening the player';

  @override
  String get playerGestures => 'Playback gestures';

  @override
  String get playerGestureSeek => 'Swipe and double-tap to seek';

  @override
  String get playerGestureSeekSubtitle =>
      'Swipe or double-tap the video to change position';

  @override
  String get playerGestureVolume => 'Swipe to adjust volume';

  @override
  String get playerGestureVolumeSubtitle =>
      'Swipe up and down on the right side of the video to adjust volume';

  @override
  String get playerGestureBrightness => 'Swipe to adjust brightness';

  @override
  String get playerGestureBrightnessSubtitle =>
      'Swipe up and down on the left side of the video to adjust brightness';

  @override
  String get playerGestureBoost => 'Hold to temporarily speed up';

  @override
  String get playerGestureBoostSubtitle =>
      'Hold the video to temporarily switch to 2x speed';

  @override
  String get playerSleepTimerDefault => 'Default sleep timer';

  @override
  String get playerSleepTimerDefaultSubtitle =>
      'Start a countdown automatically when opening the player; disabled means no automatic timer';

  @override
  String get playerSleepTimerOff => 'Off';

  @override
  String get playerSleepTimerAction => 'When the sleep timer ends';

  @override
  String get playerSleepTimerActionSubtitle =>
      'Pause immediately, finish the current video, or close the player when the timer ends';

  @override
  String get playerQualityAuto => 'Auto';

  @override
  String playerQualityHeight(String p1) {
    return '${p1}P';
  }

  @override
  String get settingsHistory => 'History';

  @override
  String get historyRecording => 'Save watch history';

  @override
  String get historyRecordingSubtitle =>
      'Keep watched videos in the local history';

  @override
  String get historyResumePlayback => 'Resume playback';

  @override
  String get historyResumePlaybackSubtitle =>
      'Continue videos from the last saved position';

  @override
  String get settingsLibrary => 'Library';

  @override
  String get libraryBookmarkSync => 'Sync bookmarks';

  @override
  String get libraryBookmarkSyncSubtitle =>
      'Keep local bookmarks in sync with remote';

  @override
  String get librarySearchHistoryRetention => 'Search history retention';

  @override
  String get librarySearchHistoryRetentionSubtitle =>
      'Delete searches older than the selected period';

  @override
  String get librarySearchHistoryRetention7Days => '7 days';

  @override
  String get librarySearchHistoryRetention30Days => '30 days';

  @override
  String get librarySearchHistoryRetention90Days => '90 days';

  @override
  String get librarySearchHistoryRetentionForever => 'Forever';

  @override
  String get danmakuSettingsSubtitle =>
      'Opacity, font size, duration and how many rows pinned at the top and bottom';

  @override
  String get clearImageCache => 'Clear image cache';

  @override
  String get clearImageCacheSubtitle =>
      'Frees decoded images held in memory; covers reload when shown again';

  @override
  String get imageCacheCleared => 'Image cache cleared';

  @override
  String get settingsAdvanced => 'Advanced';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get appearanceThemeSystem => 'System';

  @override
  String get appearanceThemeLight => 'Light';

  @override
  String get appearanceThemeDark => 'Dark';

  @override
  String get appearanceTheme => 'Theme';

  @override
  String get appearanceThemeSubtitle => 'Theme mode for the app';

  @override
  String get appearanceFontSize => 'Font Size';

  @override
  String get appearanceFontSizeSubtitle => 'Adjust text size across the app';

  @override
  String get appearanceFontSizeSmall => 'Small';

  @override
  String get appearanceFontSizeStandard => 'Standard';

  @override
  String get appearanceFontSizeLarge => 'Large';

  @override
  String get appearanceFontSizeXLarge => 'X-Large';

  @override
  String get dialogCancel => 'Cancel';

  @override
  String get actionSelectAll => 'Select All';

  @override
  String get actionDeselect => 'Deselect';

  @override
  String selectionSelected(int count) {
    return '$count selected';
  }

  @override
  String get sleepTimerTitle => 'Sleep timer';

  @override
  String get sleepTimerActionNowLabel => 'Pause now';

  @override
  String get sleepTimerAfterCurrentTitle => 'After current video';

  @override
  String get copyCreatorLink => 'Copy creator page link';

  @override
  String get trackCopiedToClipboard => 'Copied to clipboard';

  @override
  String get settings => 'Settings';

  @override
  String sourceNoRecommendations(String p1) {
    return 'No recommendations available from $p1';
  }

  @override
  String get sourceNoHomeFeed => 'This source doesn\'t provide a home feed';

  @override
  String get homeAllTabsHidden => 'All tabs are hidden';

  @override
  String get homeAllTabsHiddenHint => 'Turn tabs back on in Home settings';

  @override
  String sectionLoadFailed(String p1) {
    return 'Failed to load $p1';
  }

  @override
  String get checkNetworkRetry => 'Check your network connection and try again';

  @override
  String sectionEmpty(String p1) {
    return 'No content in $p1';
  }

  @override
  String get retry => 'Retry';

  @override
  String get switchDataSource => 'Switch source';

  @override
  String get switchVideoMediaSource => 'Switch video and media source';

  @override
  String get unknownStreamer => 'Unknown streamer';

  @override
  String streamerLabel(String p1) {
    return 'Streamer: $p1';
  }

  @override
  String get commaSeparator => ', ';

  @override
  String get continueLoading => 'Load more';

  @override
  String get noMoreItems => 'No more items';

  @override
  String get searchHint => 'Search...';

  @override
  String putIntoSearchBox(String p1) {
    return 'Put $p1 in the search box';
  }

  @override
  String get loadFailedRetryLater => 'Failed to load. Try again later';

  @override
  String get rateLimitedRetryLater =>
      'Too many requests. Please wait a moment and try again';

  @override
  String retryInSeconds(int seconds) {
    return 'Retry in ${seconds}s';
  }

  @override
  String get moreLoadFailedRetry => 'Failed to load more. Retry';

  @override
  String get nothingFound => 'Nothing found';

  @override
  String get creatorTab => 'Creators';

  @override
  String get spaceDescriptionUnavailable => 'No description available';

  @override
  String get videoTab => 'Video';

  @override
  String get clearRecentSearchHistory => 'Clear recent search history';

  @override
  String get clear => 'Clear';

  @override
  String searchQueryLabel(String p1) {
    return 'Search \"$p1\"';
  }

  @override
  String get filters => 'Filters';

  @override
  String get reset => 'Reset';

  @override
  String get confirm => 'OK';

  @override
  String get selectDateRange => 'Select date range';

  @override
  String get history => 'History';

  @override
  String get favorite => 'Favorites';

  @override
  String get playlists => 'Playlist';

  @override
  String get subscribe => 'Subscribe';

  @override
  String get allSources => 'All sources';

  @override
  String sourceLabel(String p1) {
    return 'Source: $p1';
  }

  @override
  String get filter => 'Filter';

  @override
  String get selectSource => 'Select source';

  @override
  String get deletePlaylistConfirm => 'Delete playlist?';

  @override
  String get deletePlaylistNote =>
      'Local entries in this list will also be deleted.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get noFavoritesFromSource => 'No favorites to add from this source';

  @override
  String operationFailed(String p1) {
    return 'Operation failed: $p1';
  }

  @override
  String get loadingFavorites => 'Loading favorites';

  @override
  String get favoritesLoadFailed => 'Failed to load favorites';

  @override
  String get exportFavorites => 'Export';

  @override
  String get favoritesExportFailed => 'Export failed';

  @override
  String get noFavoritesYet => 'No favorites yet';

  @override
  String get spacedDot => ' · ';

  @override
  String get favoriteActions => 'Favorite actions';

  @override
  String get openCreator => 'Open creator';

  @override
  String get unfavorite => 'Remove from favorites';

  @override
  String get loadingPlaylists => 'Loading playlists';

  @override
  String get playlistLoadFailed => 'Failed to load playlists';

  @override
  String get noPlaylistsYet => 'No playlists yet';

  @override
  String get newPlaylist => 'New playlist';

  @override
  String get playlistActions => 'Playlist actions';

  @override
  String get addFavorite => 'Add to favorites';

  @override
  String get deletePlaylist => 'Delete playlist';

  @override
  String get itemsLoadFailed => 'Failed to load items';

  @override
  String get listEmpty => 'The list is empty';

  @override
  String get itemActions => 'Item actions';

  @override
  String get moveUp => 'Move up';

  @override
  String get moveDown => 'Move down';

  @override
  String get removeThisEntry => 'Remove this entry';

  @override
  String get renamePlaylist => 'Rename playlist';

  @override
  String get renamePlaylistConfirm => 'Rename playlist';

  @override
  String get batchDeleteConfirm => 'Delete items in bulk';

  @override
  String batchDeleteNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected items',
      one: 'selected item',
    );
    return 'Delete the $_temp0? This can\'t be undone.';
  }

  @override
  String get deleteSelected => 'Delete selected';

  @override
  String get editMode => 'Edit';

  @override
  String get done => 'Done';

  @override
  String get itemsSearchHint => 'Search items...';

  @override
  String get loadingSubscriptions => 'Loading subscriptions';

  @override
  String get subscriptionsLoadFailed => 'Failed to load subscriptions';

  @override
  String get noSubscriptionsYet => 'No subscriptions yet';

  @override
  String get ungrouped => 'Ungrouped';

  @override
  String get subscriptionActions => 'Subscription actions';

  @override
  String get setGroup => 'Set group';

  @override
  String get unsubscribe => 'Unsubscribe';

  @override
  String get add => 'Add';

  @override
  String get source => 'Source';

  @override
  String get name => 'Name';

  @override
  String get create => 'Create';

  @override
  String get groupName => 'Group name';

  @override
  String get groupNameHint => 'Leave empty for ungrouped';

  @override
  String get save => 'Save';

  @override
  String get mine => 'Me';

  @override
  String get watchHistory => 'Watch history';

  @override
  String watchHistoryLoadedCount(String p1) {
    return 'Watch history · $p1 loaded';
  }

  @override
  String tabLoadFailed(String p1) {
    return '$p1 · Failed to load';
  }

  @override
  String get loadMore => 'Load more';

  @override
  String get loadingHistory => 'Loading history...';

  @override
  String get loadMoreHistory => 'Load more history';

  @override
  String get historyLoadFailed => 'Failed to load history';

  @override
  String get noWatchHistory => 'No watch history yet';

  @override
  String durationLabel(String p1) {
    return 'Duration $p1';
  }

  @override
  String watchedAt(String p1) {
    return 'Watched $p1';
  }

  @override
  String get finishedWatching => 'Finished';

  @override
  String watchedDuration(String p1) {
    return 'Watched $p1';
  }

  @override
  String get justNow => 'Just Now';

  @override
  String minutesAgo(int p1) {
    String _temp0 = intl.Intl.pluralLogic(
      p1,
      locale: localeName,
      other: '$p1 minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int p1) {
    String _temp0 = intl.Intl.pluralLogic(
      p1,
      locale: localeName,
      other: '$p1 hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int p1) {
    String _temp0 = intl.Intl.pluralLogic(
      p1,
      locale: localeName,
      other: '$p1 days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get addToPlaylistTitle => 'Add to Playlist';

  @override
  String addToNamedPlaylist(String p1) {
    return 'Add to $p1';
  }

  @override
  String addToNamedPlaylistLong(String p1) {
    return 'Add to playlist $p1';
  }

  @override
  String addFailed(String p1) {
    return 'Failed to add: $p1';
  }

  @override
  String createOrAddFailed(String p1) {
    return 'Failed to create or add: $p1';
  }

  @override
  String get playlistNameRequired => 'Enter a playlist name';

  @override
  String get infoAndRelated => 'Info & related';

  @override
  String get commentsTab => 'Comments';

  @override
  String get danmakuSettingsTitle => 'Danmaku settings';

  @override
  String get showDanmaku => 'Show danmaku';

  @override
  String get showTimelineDanmakuOnVideo =>
      'Show timeline danmaku over the video';

  @override
  String get regularDanmakuDuration => 'Regular danmaku duration';

  @override
  String secondsValue(String p1) {
    return '$p1 s';
  }

  @override
  String get opacity => 'Opacity';

  @override
  String get fontSize => 'Font size';

  @override
  String get strokeRadius => 'Stroke radius';

  @override
  String get playbackSpeed => 'Speed';

  @override
  String get auto => 'Auto';

  @override
  String get qualitySelect => 'Select quality';

  @override
  String get singleQualityOnly => 'This source offers only one quality';

  @override
  String get afterCurrentItem => 'After current';

  @override
  String get timer => 'Timer';

  @override
  String minutesValue(String p1) {
    return '$p1 min';
  }

  @override
  String get cancelTimer => 'Cancel timer';

  @override
  String get sleepTimerCustom => 'Custom';

  @override
  String get sleepTimerCustomTitle => 'Custom sleep timer';

  @override
  String sleepTimerCustomValue(String p1) {
    return '$p1 min';
  }

  @override
  String get sleepTimerMinutesHint => 'Minutes';

  @override
  String get sleepTimerInvalidDuration =>
      'Enter a duration from 1 to 1440 minutes.';

  @override
  String countCompactWan(String p1) {
    return '$p1万';
  }

  @override
  String get commentsUnsupportedSource =>
      'This source doesn\'t support comments';

  @override
  String get commentsLoadFailed => 'Failed to load comments. Try again later';

  @override
  String get noComments => 'No comments yet';

  @override
  String likeCommentCount(String p1) {
    return 'Like comment $p1';
  }

  @override
  String get unlikeComment => 'Unlike comment';

  @override
  String get likeComment => 'Like comment';

  @override
  String get collapseReplies => 'Collapse replies';

  @override
  String viewReplyCount(String p1) {
    return 'View $p1 replies';
  }

  @override
  String get repliesUnavailable => 'Replies aren\'t available yet';

  @override
  String get videoLoadFailed => 'Failed to load video. Try again';

  @override
  String get noRecommendations => 'No related recommendations';

  @override
  String viewCountLabel(String p1) {
    return '$p1 views';
  }

  @override
  String get dotSeparator => '·';

  @override
  String danmakuCountLabel(String p1) {
    return '$p1 danmaku';
  }

  @override
  String get copyrightOriginal => 'Original';

  @override
  String get copyrightRepost => 'Reposted';

  @override
  String get unfollowCreator => 'Unfollow creator';

  @override
  String get followCreator => 'Follow creator';

  @override
  String followingCreatorNamed(String p1) {
    return 'Following creator $p1';
  }

  @override
  String followCreatorNamed(String p1) {
    return 'Follow creator $p1';
  }

  @override
  String get following => 'Following';

  @override
  String get follow => 'Follow';

  @override
  String get like => 'Like';

  @override
  String get list => 'List';

  @override
  String get addToPlaylist => 'Add to playlist';

  @override
  String get addToLocalPlaylist => 'Add to local playlist';

  @override
  String get switchSource => 'Switch source';

  @override
  String get switchVideoSource => 'Switch video source';

  @override
  String get autoSwitchBestRoute =>
      'Automatically switch to the best available route';

  @override
  String get share => 'Share';

  @override
  String get shareVideo => 'Share video';

  @override
  String get shareMultiSourceLink => 'Share multi-source video link';

  @override
  String get danmakuStateOn => 'Danmaku on';

  @override
  String get danmakuStateOff => 'Danmaku off';

  @override
  String get danmaku => 'Danmaku';

  @override
  String get danmakuActionOff => 'Turn danmaku off';

  @override
  String get danmakuActionOn => 'Turn danmaku on';

  @override
  String get synopsisSectionTitle => 'Summary & key takeaways';

  @override
  String get collapseSynopsis => 'Collapse summary';

  @override
  String get expandSynopsis => 'Expand full outline';

  @override
  String get collapse => 'Collapse';

  @override
  String get sampleSynopsisFallback =>
      'An in-depth look at why Flutter moved from Skia to Impeller for rendering. Covers shader precompilation, RenderPass reuse, direct Metal / Vulkan backend binding, and techniques for eliminating frame drops on mobile.';

  @override
  String get chapters => 'Chapters';

  @override
  String get multiSourceRecommendations => 'Multi-source recommendations';

  @override
  String get addingToQueue => 'Adding to queue';

  @override
  String get addToPlayQueue => 'Add to play queue';

  @override
  String get addedToPlayQueue => 'Added to play queue';

  @override
  String get addToQueueFailed => 'Failed to add to queue';

  @override
  String cancelAction(String p1) {
    return 'Cancel $p1';
  }

  @override
  String get previousItem => 'Previous';

  @override
  String get nextItem => 'Next';

  @override
  String get loopOff => 'Loop: off';

  @override
  String get loopOne => 'Repeat one';

  @override
  String get loopQueue => 'Repeat queue';

  @override
  String get minimize => 'Minimize';

  @override
  String get playbackErrorNetwork => 'Network error';

  @override
  String get playbackErrorOpen => 'Stream failed to open';

  @override
  String get playbackErrorDecoder => 'Decoder error';

  @override
  String get playbackErrorDrm => 'DRM error';

  @override
  String get playbackErrorAuthorization => 'Authorization error';

  @override
  String get playbackErrorUnknown => 'Unknown playback error';

  @override
  String get playbackRetrying => 'Retrying...';

  @override
  String get skip => 'Skip';

  @override
  String get back => 'Back';

  @override
  String get fullscreen => 'Fullscreen';

  @override
  String get highBitrate1080 => '1080P high bitrate';

  @override
  String get pause => 'Pause';

  @override
  String get play => 'Play';

  @override
  String get fullscreenToggle => 'Toggle fullscreen';

  @override
  String get sourceUnavailable => 'Source unavailable';

  @override
  String countCompactYi(String p1) {
    return '$p1亿';
  }

  @override
  String yearsAgoCompact(int p1) {
    String _temp0 = intl.Intl.pluralLogic(
      p1,
      locale: localeName,
      other: '$p1 years ago',
      one: '1 year ago',
    );
    return '$_temp0';
  }

  @override
  String monthsAgoCompact(int p1) {
    String _temp0 = intl.Intl.pluralLogic(
      p1,
      locale: localeName,
      other: '$p1 months ago',
      one: '1 month ago',
    );
    return '$_temp0';
  }

  @override
  String viewsWithDate(String p1, String p2) {
    return '$p1 views • $p2';
  }

  @override
  String viewsCount(String p1) {
    return '$p1 views';
  }

  @override
  String get spacedBullet => ' • ';

  @override
  String creatorLabel(String p1) {
    return 'Creator: $p1';
  }

  @override
  String durationPrefix(String p1) {
    return 'Duration $p1';
  }

  @override
  String get unknownCreator => 'Unknown creator';

  @override
  String get loadingWatchLater => 'Loading Watch later';

  @override
  String get watchLaterLoadFailed => 'Watch later failed to load';

  @override
  String get watchLaterEmpty => 'Nothing saved for later yet';

  @override
  String get watchLater => 'Watch later';

  @override
  String get saveToWatchLater => 'Save to Watch later';

  @override
  String get removeFromWatchLater => 'Remove from Watch later';

  @override
  String get savedToWatchLater => 'Saved to Watch later';

  @override
  String get removedFromWatchLater => 'Removed from Watch later';

  @override
  String get moreOptions => 'More options';

  @override
  String subscribersCount(String p1) {
    return '$p1 followers';
  }

  @override
  String videosCount(String p1) {
    return '$p1 videos';
  }

  @override
  String get liveNow => 'Live now';

  @override
  String get navDiscoverLabel => 'Discover';

  @override
  String get navSubscriptionLabel => 'Subscriptions';

  @override
  String get search => 'Search';

  @override
  String get liveSourceUnavailable =>
      'The live stream\'s source is unavailable';

  @override
  String get creatorSourceUnavailable => 'The creator\'s source is unavailable';

  @override
  String get videoSourceUnavailable => 'The video\'s source is unavailable';

  @override
  String get videoDetailSourceUnsupported =>
      'This source doesn\'t support video details yet';

  @override
  String get progress => 'Progress';

  @override
  String get switchAction => 'Switch';

  @override
  String get playbackQueue => 'Playback queue';

  @override
  String playbackQueueCount(int count) {
    return '$count items';
  }

  @override
  String queueItemFallback(int count) {
    return 'Video $count';
  }

  @override
  String get queueEmpty => 'Your playback queue is empty';

  @override
  String get removeFromQueue => 'Remove from queue';

  @override
  String get currentlyPlaying => 'Currently playing';

  @override
  String get playPlaylist => 'Play all';

  @override
  String get playlistPlaybackFailed => 'Could not start this playlist';

  @override
  String get settingsDiscovery => 'Discovery';

  @override
  String get settingsChannel => 'Channel';

  @override
  String get settingsSaveFailed => 'Couldn\'t save the setting';

  @override
  String get homeConfigTitle => 'Discovery';

  @override
  String get homeConfigTabs => 'Tabs';

  @override
  String get homeConfigNoTabs => 'No tabs to configure';

  @override
  String get homeConfigMoveUp => 'Move up';

  @override
  String get homeConfigMoveDown => 'Move down';

  @override
  String get homeConfigSetMain => 'Set as main';

  @override
  String get homeConfigGridColumns => 'Grid columns';

  @override
  String get homeConfigPortrait => 'Portrait';

  @override
  String get homeConfigLandscape => 'Landscape';

  @override
  String get homeConfigVisible => 'Visible';

  @override
  String get homeConfigHidden => 'Hidden';

  @override
  String get liveRoomLoading => 'Loading live room';

  @override
  String get liveScreenTitle => 'Live';

  @override
  String get liveRoomError => 'Failed to load live room';

  @override
  String get liveStreamError => 'Failed to load live stream';

  @override
  String get liveViewers => 'watching';

  @override
  String get liveRoomEnded => 'Stream ended';

  @override
  String get recentSearches => 'Recent searches';

  @override
  String get clearAllSearchHistory => 'Clear all search history';

  @override
  String get clearAllWatchHistory => 'Clear all watch history';

  @override
  String get clearWatchHistoryConfirm => 'Clear all watch history?';

  @override
  String get clearWatchHistoryMessage =>
      'This removes every entry from your watch history. The action cannot be undone.';

  @override
  String get historyItemRemoved => 'Removed from history';

  @override
  String get watchHistoryCleared => 'Watch history cleared';

  @override
  String get noSearchHistory => 'No search history yet';

  @override
  String deleteHistoryItemConfirm(String p1) {
    return 'Delete \"$p1\" from history?';
  }

  @override
  String get playlistTitle => 'Playlist';

  @override
  String get playlistSourceUnavailable =>
      'The source of this playlist is unavailable';

  @override
  String get playlistEmpty => 'This playlist has no videos yet';

  @override
  String get playlistDescriptionUnavailable => 'No description';

  @override
  String playlistItemCount(String count) {
    return '$count videos';
  }

  @override
  String get playlistFetchAll => 'Fetch all';

  @override
  String playlistFetchAllProgress(String count) {
    return 'Fetched $count';
  }

  @override
  String playlistFetchAllDone(String count) {
    return 'Fetched all $count videos';
  }

  @override
  String playlistFetchAllPartial(String count) {
    return 'Fetched $count videos before the fetch stopped';
  }

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get feedUpdateNotifications => 'Feed update notifications';

  @override
  String get feedUpdateNotificationsSubtitle =>
      'Notify when new feed items are detected';

  @override
  String get feedUpdateThreshold => 'Notification threshold';

  @override
  String get feedUpdateThresholdSubtitle =>
      'Only notify when new items reach this count';

  @override
  String feedUpdateThresholdOption(int count) {
    return '$count items';
  }

  @override
  String get feedUpdateThresholdOff => 'Off';

  @override
  String get feedTitle => 'Subscription feed';

  @override
  String feedUnreadCount(int count) {
    return '$count unread';
  }

  @override
  String get feedMarkAllRead => 'Mark all as read';

  @override
  String feedExpandChannel(String channel) {
    return 'Expand $channel';
  }

  @override
  String feedCollapseChannel(String channel) {
    return 'Collapse $channel';
  }

  @override
  String get feedEmptyTitle => 'No subscription updates yet';

  @override
  String get feedEmptyDescription =>
      'New posts from channels you follow will appear here';

  @override
  String get feedUnsupportedTitle => 'This source has no subscription feed';

  @override
  String get feedUpdateNotificationTitle => 'New feed items';

  @override
  String feedUpdateNotificationBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new items in your feed',
      one: '1 new item in your feed',
    );
    return '$_temp0';
  }

  @override
  String get channelVideosUnsupported => 'This source has no channel videos';

  @override
  String get channelVideosEmpty => 'No videos yet';

  @override
  String get channelTabPlaylists => 'Playlists';

  @override
  String get channelPlaylistsEmpty => 'No playlists yet';

  @override
  String get sleepTimerActionExitPlayerLabel => 'Close player';

  @override
  String get sleepTimerDuration => 'Duration';

  @override
  String get sleepTimerEndingSoonTitle => 'Sleep timer';

  @override
  String get sleepTimerEndingSoonBody => 'Playback stops in 1 minute';

  @override
  String get sleepTimerChannelName => 'Sleep timer';

  @override
  String get sleepTimerChannelDescription =>
      'Warns one minute before playback stops';
}
