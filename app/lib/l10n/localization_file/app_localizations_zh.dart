// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get searchResultTypeAll => '全部';

  @override
  String get searchResultTypeVideo => '视频';

  @override
  String get searchResultTypeChannel => '频道';

  @override
  String get searchResultTypeLive => '直播';

  @override
  String get searchResultTypePlaylist => '播放列表';

  @override
  String get navSettings => '设置';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsGroupPlayback => '播放与外观';

  @override
  String get settingsGroupLibrary => '媒体库与通知';

  @override
  String get settingsGroupDiscovery => '发现与频道';

  @override
  String get settingsGroupOther => '更多';

  @override
  String get settingsPlayer => '播放器';

  @override
  String get playerDefaultQuality => '默认画质';

  @override
  String get playerDefaultQualitySubtitle => '进入播放器时优先使用的画质';

  @override
  String get playerDefaultSpeed => '默认倍速';

  @override
  String get playerDefaultSpeedSubtitle => '进入播放器时优先使用的播放速度';

  @override
  String get playerGestures => '播放手势';

  @override
  String get playerGestureSeek => '滑动与双击快进';

  @override
  String get playerGestureSeekSubtitle => '在画面上滑动或双击调整播放位置';

  @override
  String get playerGestureVolume => '滑动调节音量';

  @override
  String get playerGestureVolumeSubtitle => '在画面右侧上下滑动调节音量';

  @override
  String get playerGestureBrightness => '滑动调节亮度';

  @override
  String get playerGestureBrightnessSubtitle => '在画面左侧上下滑动调节亮度';

  @override
  String get playerGestureBoost => '长按临时加速';

  @override
  String get playerGestureBoostSubtitle => '长按画面临时切换到 2 倍速';

  @override
  String get playerSleepTimerDefault => '睡眠定时器默认值';

  @override
  String get playerSleepTimerDefaultSubtitle => '进入播放器时自动开始倒计时，关闭则不自动计时';

  @override
  String get playerSleepTimerOff => '关闭';

  @override
  String get playerSleepTimerAction => '睡眠定时结束行为';

  @override
  String get playerSleepTimerActionSubtitle => '选择倒计时结束后立即暂停、播完当前视频再停，还是关闭播放器';

  @override
  String get playerQualityAuto => '自动';

  @override
  String playerQualityHeight(String p1) {
    return '${p1}P';
  }

  @override
  String get settingsHistory => '历史记录';

  @override
  String get historyRecording => '保存观看历史';

  @override
  String get historyRecordingSubtitle => '把看过的视频保存在本地历史中';

  @override
  String get historyResumePlayback => '续播';

  @override
  String get historyResumePlaybackSubtitle => '从上次保存的位置继续播放';

  @override
  String get settingsLibrary => '媒体库';

  @override
  String get libraryBookmarkSync => '同步收藏';

  @override
  String get libraryBookmarkSyncSubtitle => '将本地收藏与远端保持同步';

  @override
  String get librarySearchHistoryRetention => '搜索历史保留';

  @override
  String get librarySearchHistoryRetentionSubtitle => '删除早于选定周期的搜索记录';

  @override
  String get librarySearchHistoryRetention7Days => '7 天';

  @override
  String get librarySearchHistoryRetention30Days => '30 天';

  @override
  String get librarySearchHistoryRetention90Days => '90 天';

  @override
  String get librarySearchHistoryRetentionForever => '永久';

  @override
  String get danmakuSettingsSubtitle => '不透明度、字号、停留时长，以及顶部与底部各固定几行';

  @override
  String get clearImageCache => '清除图片缓存';

  @override
  String get clearImageCacheSubtitle => '释放内存中已解码的图片，封面在再次显示时重新解码';

  @override
  String get imageCacheCleared => '图片缓存已清除';

  @override
  String get settingsAdvanced => '高级';

  @override
  String get settingsAppearance => '外观';

  @override
  String get appearanceThemeSystem => '跟随系统';

  @override
  String get appearanceThemeLight => '浅色';

  @override
  String get appearanceThemeDark => '深色';

  @override
  String get appearanceTheme => '主题';

  @override
  String get appearanceThemeSubtitle => '应用的主题模式';

  @override
  String get appearanceFontSize => '字号';

  @override
  String get appearanceFontSizeSubtitle => '调整应用内文字大小';

  @override
  String get appearanceFontSizeSmall => '小';

  @override
  String get appearanceFontSizeStandard => '标准';

  @override
  String get appearanceFontSizeLarge => '大';

  @override
  String get appearanceFontSizeXLarge => '特大';

  @override
  String get dialogCancel => '取消';

  @override
  String get actionSelectAll => '全选';

  @override
  String get actionDeselect => '取消全选';

  @override
  String selectionSelected(int count) {
    return '已选择 $count 项';
  }

  @override
  String get sleepTimerTitle => '睡眠定时器';

  @override
  String get sleepTimerActionNowLabel => '到时暂停';

  @override
  String get sleepTimerAfterCurrentTitle => '播完本条即停';

  @override
  String get copyCreatorLink => '复制创作者主页链接';

  @override
  String get trackCopiedToClipboard => '已复制到剪贴板';

  @override
  String get settings => '设置';

  @override
  String sourceNoRecommendations(String p1) {
    return '$p1 暂无可用推荐';
  }

  @override
  String get sourceNoHomeFeed => '该数据源未提供首页 Feed';

  @override
  String get homeAllTabsHidden => '标签页已全部隐藏';

  @override
  String get homeAllTabsHiddenHint => '在首页设置中重新显示标签页';

  @override
  String sectionLoadFailed(String p1) {
    return '$p1 加载失败';
  }

  @override
  String get checkNetworkRetry => '请检查网络连接后重试';

  @override
  String sectionEmpty(String p1) {
    return '$p1 暂无内容';
  }

  @override
  String get retry => '重试';

  @override
  String get switchDataSource => '切换数据源';

  @override
  String get switchVideoMediaSource => '切换视频与媒体数据源';

  @override
  String get unknownStreamer => '未知主播';

  @override
  String streamerLabel(String p1) {
    return '主播: $p1';
  }

  @override
  String get commaSeparator => '，';

  @override
  String get continueLoading => '继续加载';

  @override
  String get noMoreItems => '没有更多了';

  @override
  String get searchHint => '搜索...';

  @override
  String putIntoSearchBox(String p1) {
    return '$p1 放入搜索框';
  }

  @override
  String get loadFailedRetryLater => '加载失败，请稍后重试';

  @override
  String get rateLimitedRetryLater => '操作过快，请稍后再试';

  @override
  String retryInSeconds(int seconds) {
    return '$seconds 秒后可重试';
  }

  @override
  String get moreLoadFailedRetry => '更多数据加载失败，重试';

  @override
  String get nothingFound => '未找到内容';

  @override
  String get creatorTab => '创作者';

  @override
  String get spaceDescriptionUnavailable => '暂无简介';

  @override
  String get videoTab => '视频';

  @override
  String get clearRecentSearchHistory => '清空最近搜索历史';

  @override
  String get clear => '清空';

  @override
  String searchQueryLabel(String p1) {
    return '搜索 \"$p1\"';
  }

  @override
  String get filters => '筛选器';

  @override
  String get reset => '重置';

  @override
  String get confirm => '确定';

  @override
  String get selectDateRange => '选择日期范围';

  @override
  String get history => '历史';

  @override
  String get favorite => '收藏';

  @override
  String get playlists => '播放列表';

  @override
  String get subscribe => '订阅';

  @override
  String get allSources => '全部来源';

  @override
  String sourceLabel(String p1) {
    return '来源：$p1';
  }

  @override
  String get filter => '筛选';

  @override
  String get selectSource => '选择来源';

  @override
  String get deletePlaylistConfirm => '删除播放列表？';

  @override
  String get deletePlaylistNote => '列表中的本地条目也会被删除。';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get noFavoritesFromSource => '该来源没有可添加的收藏';

  @override
  String operationFailed(String p1) {
    return '操作失败：$p1';
  }

  @override
  String get loadingFavorites => '正在加载收藏';

  @override
  String get favoritesLoadFailed => '收藏加载失败';

  @override
  String get exportFavorites => '导出';

  @override
  String get favoritesExportFailed => '导出失败';

  @override
  String get noFavoritesYet => '还没有收藏';

  @override
  String get spacedDot => ' · ';

  @override
  String get favoriteActions => '收藏操作';

  @override
  String get openCreator => '打开创作者';

  @override
  String get unfavorite => '取消收藏';

  @override
  String get loadingPlaylists => '正在加载播放列表';

  @override
  String get playlistLoadFailed => '播放列表加载失败';

  @override
  String get noPlaylistsYet => '还没有播放列表';

  @override
  String get newPlaylist => '新建播放列表';

  @override
  String get playlistActions => '播放列表操作';

  @override
  String get addFavorite => '添加收藏';

  @override
  String get deletePlaylist => '删除播放列表';

  @override
  String get itemsLoadFailed => '条目加载失败';

  @override
  String get listEmpty => '列表为空';

  @override
  String get itemActions => '条目操作';

  @override
  String get moveUp => '上移';

  @override
  String get moveDown => '下移';

  @override
  String get removeThisEntry => '移除这一次';

  @override
  String get renamePlaylist => '重命名播放列表';

  @override
  String get renamePlaylistConfirm => '重命名播放列表';

  @override
  String get batchDeleteConfirm => '批量删除条目';

  @override
  String batchDeleteNote(int count) {
    return '确定删除选中的 $count 个条目？此操作不可撤销。';
  }

  @override
  String get deleteSelected => '删除选中';

  @override
  String get editMode => '编辑';

  @override
  String get done => '完成';

  @override
  String get itemsSearchHint => '搜索条目...';

  @override
  String get loadingSubscriptions => '正在加载订阅';

  @override
  String get subscriptionsLoadFailed => '订阅加载失败';

  @override
  String get noSubscriptionsYet => '还没有订阅';

  @override
  String get ungrouped => '未分组';

  @override
  String get subscriptionActions => '订阅操作';

  @override
  String get setGroup => '设置分组';

  @override
  String get unsubscribe => '取消订阅';

  @override
  String get add => '添加';

  @override
  String get source => '来源';

  @override
  String get name => '名称';

  @override
  String get create => '创建';

  @override
  String get groupName => '分组名称';

  @override
  String get groupNameHint => '留空表示未分组';

  @override
  String get save => '保存';

  @override
  String get mine => '我的';

  @override
  String get watchHistory => '观看历史';

  @override
  String watchHistoryLoadedCount(String p1) {
    return '观看历史 · 已载入 $p1 条';
  }

  @override
  String tabLoadFailed(String p1) {
    return '$p1 · 加载失败';
  }

  @override
  String get loadMore => '加载更多';

  @override
  String get loadingHistory => '正在加载历史记录...';

  @override
  String get loadMoreHistory => '加载更多历史记录';

  @override
  String get historyLoadFailed => '历史记录加载失败';

  @override
  String get noWatchHistory => '还没有观看记录';

  @override
  String durationLabel(String p1) {
    return '时长 $p1';
  }

  @override
  String watchedAt(String p1) {
    return '观看于 $p1';
  }

  @override
  String get finishedWatching => '已看完';

  @override
  String watchedDuration(String p1) {
    return '已观看 $p1';
  }

  @override
  String get justNow => '刚刚';

  @override
  String minutesAgo(int p1) {
    return '$p1 分钟前';
  }

  @override
  String hoursAgo(int p1) {
    return '$p1 小时前';
  }

  @override
  String daysAgo(int p1) {
    return '$p1 天前';
  }

  @override
  String get addToPlaylistTitle => '添加到播放列表';

  @override
  String addToNamedPlaylist(String p1) {
    return '添加到 $p1';
  }

  @override
  String addToNamedPlaylistLong(String p1) {
    return '添加到播放列表 $p1';
  }

  @override
  String addFailed(String p1) {
    return '添加失败：$p1';
  }

  @override
  String createOrAddFailed(String p1) {
    return '创建或添加失败：$p1';
  }

  @override
  String get playlistNameRequired => '请输入播放列表名称';

  @override
  String get infoAndRelated => '简介与相关';

  @override
  String get commentsTab => '评论区';

  @override
  String get danmakuSettingsTitle => '弹幕设置';

  @override
  String get showDanmaku => '显示弹幕';

  @override
  String get showTimelineDanmakuOnVideo => '在视频画面上显示时间轴弹幕';

  @override
  String get regularDanmakuDuration => '普通弹幕时长';

  @override
  String secondsValue(String p1) {
    return '$p1 秒';
  }

  @override
  String get opacity => '不透明度';

  @override
  String get fontSize => '字号';

  @override
  String get strokeRadius => '描边半径';

  @override
  String get playbackSpeed => '倍速';

  @override
  String get auto => '自动';

  @override
  String get qualitySelect => '画质选择';

  @override
  String get singleQualityOnly => '当前源只提供一个档位';

  @override
  String get afterCurrentItem => '播完本条';

  @override
  String get timer => '定时';

  @override
  String minutesValue(String p1) {
    return '$p1 分钟';
  }

  @override
  String get cancelTimer => '取消定时';

  @override
  String get sleepTimerCustom => '自定义';

  @override
  String get sleepTimerCustomTitle => '自定义睡眠定时';

  @override
  String sleepTimerCustomValue(String p1) {
    return '$p1 分钟';
  }

  @override
  String get sleepTimerMinutesHint => '分钟';

  @override
  String get sleepTimerInvalidDuration => '请输入 1 到 1440 分钟之间的时长。';

  @override
  String countCompactWan(String p1) {
    return '$p1万';
  }

  @override
  String get commentsUnsupportedSource => '当前数据源暂不支持评论';

  @override
  String get commentsLoadFailed => '评论加载失败，请稍后重试';

  @override
  String get noComments => '暂无评论';

  @override
  String likeCommentCount(String p1) {
    return '点赞评论 $p1';
  }

  @override
  String get unlikeComment => '取消点赞';

  @override
  String get likeComment => '点赞评论';

  @override
  String get collapseReplies => '收起回复';

  @override
  String viewReplyCount(String p1) {
    return '查看 $p1 条回复';
  }

  @override
  String get repliesUnavailable => '评论回复暂不可用';

  @override
  String get videoLoadFailed => '视频加载失败，请重试';

  @override
  String get noRecommendations => '暂无关联推荐';

  @override
  String viewCountLabel(String p1) {
    return '$p1 播放';
  }

  @override
  String get dotSeparator => '·';

  @override
  String danmakuCountLabel(String p1) {
    return '$p1 弹幕';
  }

  @override
  String get copyrightOriginal => '原创';

  @override
  String get copyrightRepost => '转载';

  @override
  String get unfollowCreator => '取消关注创作者';

  @override
  String get followCreator => '关注创作者';

  @override
  String followingCreatorNamed(String p1) {
    return '已关注创作者 $p1';
  }

  @override
  String followCreatorNamed(String p1) {
    return '关注创作者 $p1';
  }

  @override
  String get following => '已关注';

  @override
  String get follow => '关注';

  @override
  String get like => '点赞';

  @override
  String get list => '列表';

  @override
  String get addToPlaylist => '加入播放列表';

  @override
  String get addToLocalPlaylist => '加入本地播放列表';

  @override
  String get switchSource => '多源换源';

  @override
  String get switchVideoSource => '切换视频数据源';

  @override
  String get autoSwitchBestRoute => '自动切换至最优可用的解析线路';

  @override
  String get share => '分享';

  @override
  String get shareVideo => '分享视频';

  @override
  String get shareMultiSourceLink => '分享多源视频链接';

  @override
  String get danmakuStateOn => '弹幕开';

  @override
  String get danmakuStateOff => '弹幕关';

  @override
  String get danmaku => '弹幕';

  @override
  String get danmakuActionOff => '关闭弹幕';

  @override
  String get danmakuActionOn => '开启弹幕';

  @override
  String get synopsisSectionTitle => '本期摘要 & 核心技术点';

  @override
  String get collapseSynopsis => '收起摘要';

  @override
  String get expandSynopsis => '展开完整大纲';

  @override
  String get collapse => '收起';

  @override
  String get sampleSynopsisFallback =>
      '探讨 Flutter 从 Skia 全面转向 Impeller 的底层渲染考量。详尽拆解 Shader 预编译、RenderPass 复用机制、Metal / Vulkan 直接后端绑定以及移动平台掉帧消除实践方案。';

  @override
  String get chapters => '章节';

  @override
  String get multiSourceRecommendations => '多源关联推荐';

  @override
  String get addingToQueue => '正在加入队列';

  @override
  String get addToPlayQueue => '加入播放队列';

  @override
  String get addedToPlayQueue => '已加入播放队列';

  @override
  String get addToQueueFailed => '加入队列失败';

  @override
  String cancelAction(String p1) {
    return '取消$p1';
  }

  @override
  String get previousItem => '上一首';

  @override
  String get nextItem => '下一首';

  @override
  String get loopOff => '循环：关闭';

  @override
  String get loopOne => '单首循环';

  @override
  String get loopQueue => '队列循环';

  @override
  String get minimize => '最小化';

  @override
  String get playbackErrorNetwork => '网络错误';

  @override
  String get playbackErrorOpen => '无法打开播放地址';

  @override
  String get playbackErrorDecoder => '解码错误';

  @override
  String get playbackErrorDrm => 'DRM 错误';

  @override
  String get playbackErrorAuthorization => '授权错误';

  @override
  String get playbackErrorUnknown => '未知播放错误';

  @override
  String get playbackRetrying => '正在重试...';

  @override
  String get skip => '跳过';

  @override
  String get back => '返回';

  @override
  String get fullscreen => '全屏';

  @override
  String get highBitrate1080 => '1080P 高码率';

  @override
  String get pause => '暂停';

  @override
  String get play => '播放';

  @override
  String get fullscreenToggle => '全屏切换';

  @override
  String get sourceUnavailable => '数据源不可用';

  @override
  String countCompactYi(String p1) {
    return '$p1亿';
  }

  @override
  String yearsAgoCompact(int p1) {
    return '$p1 年前';
  }

  @override
  String monthsAgoCompact(int p1) {
    return '$p1 个月前';
  }

  @override
  String viewsWithDate(String p1, String p2) {
    return '$p1 观看 • $p2';
  }

  @override
  String viewsCount(String p1) {
    return '$p1 观看';
  }

  @override
  String get spacedBullet => ' • ';

  @override
  String creatorLabel(String p1) {
    return '创作者: $p1';
  }

  @override
  String durationPrefix(String p1) {
    return '时长 $p1';
  }

  @override
  String get unknownCreator => '未知创作者';

  @override
  String get moreOptions => '更多选项';

  @override
  String subscribersCount(String p1) {
    return '$p1 关注';
  }

  @override
  String videosCount(String p1) {
    return '$p1 视频';
  }

  @override
  String get liveNow => '直播中';

  @override
  String get navDiscoverLabel => '发现';

  @override
  String get navSubscriptionLabel => '订阅';

  @override
  String get search => '搜索';

  @override
  String get liveSourceUnavailable => '直播所属的数据源不可用';

  @override
  String get creatorSourceUnavailable => '创作者所属的数据源不可用';

  @override
  String get videoSourceUnavailable => '视频所属的数据源不可用';

  @override
  String get videoDetailSourceUnsupported => '当前数据源暂不支持查看视频详情';

  @override
  String get progress => '进度';

  @override
  String get switchAction => '切换';

  @override
  String get playbackQueue => '播放队列';

  @override
  String playbackQueueCount(int count) {
    return '$count 项';
  }

  @override
  String queueItemFallback(int count) {
    return '视频 $count';
  }

  @override
  String get queueEmpty => '播放队列为空';

  @override
  String get removeFromQueue => '从队列移除';

  @override
  String get currentlyPlaying => '正在播放';

  @override
  String get playPlaylist => '播放全部';

  @override
  String get playlistPlaybackFailed => '无法开始播放此播放列表';

  @override
  String get settingsDiscovery => '发现';

  @override
  String get settingsChannel => '频道';

  @override
  String get settingsSaveFailed => '设置保存失败';

  @override
  String get homeConfigTitle => '发现';

  @override
  String get homeConfigTabs => '标签页';

  @override
  String get homeConfigNoTabs => '暂无标签页可设置';

  @override
  String get homeConfigMoveUp => '上移';

  @override
  String get homeConfigMoveDown => '下移';

  @override
  String get homeConfigSetMain => '设为主标签';

  @override
  String get homeConfigGridColumns => '网格列数';

  @override
  String get homeConfigPortrait => '竖屏';

  @override
  String get homeConfigLandscape => '横屏';

  @override
  String get homeConfigVisible => '显示';

  @override
  String get homeConfigHidden => '隐藏';

  @override
  String get liveRoomLoading => '直播间加载中';

  @override
  String get liveScreenTitle => '直播间';

  @override
  String get liveRoomError => '直播间加载失败';

  @override
  String get liveStreamError => '直播流加载失败';

  @override
  String get liveViewers => '观看';

  @override
  String get liveRoomEnded => '直播已结束';

  @override
  String get recentSearches => '最近搜索';

  @override
  String get clearAllSearchHistory => '清空搜索历史';

  @override
  String get clearAllWatchHistory => '清空观看历史';

  @override
  String get clearWatchHistoryConfirm => '清空全部观看历史？';

  @override
  String get clearWatchHistoryMessage => '这将移除观看历史中的全部记录。此操作不可撤销。';

  @override
  String get historyItemRemoved => '已从历史中移除';

  @override
  String get watchHistoryCleared => '观看历史已清空';

  @override
  String get noSearchHistory => '暂无搜索历史';

  @override
  String deleteHistoryItemConfirm(String p1) {
    return '从历史中删除 \"$p1\"？';
  }

  @override
  String get playlistTitle => '播放列表';

  @override
  String get playlistSourceUnavailable => '该播放列表所属的数据源不可用';

  @override
  String get playlistEmpty => '这个播放列表还没有视频';

  @override
  String get playlistDescriptionUnavailable => '暂无简介';

  @override
  String playlistItemCount(String count) {
    return '$count 个视频';
  }

  @override
  String get playlistFetchAll => '下载全部';

  @override
  String playlistFetchAllProgress(String count) {
    return '已下载 $count';
  }

  @override
  String playlistFetchAllDone(String count) {
    return '已下载全部 $count 个视频';
  }

  @override
  String playlistFetchAllPartial(String count) {
    return '下载中断，已下载 $count 个视频';
  }

  @override
  String get settingsNotifications => '通知';

  @override
  String get feedUpdateNotifications => 'Feed 更新通知';

  @override
  String get feedUpdateNotificationsSubtitle => '检测到新 Feed 条目时发送通知';

  @override
  String get feedUpdateThreshold => '通知阈值';

  @override
  String get feedUpdateThresholdSubtitle => '仅当新条目数达到此值时才通知';

  @override
  String feedUpdateThresholdOption(int count) {
    return '$count 条';
  }

  @override
  String get feedUpdateThresholdOff => '关闭';

  @override
  String get feedTitle => '订阅动态';

  @override
  String feedUnreadCount(int count) {
    return '$count 条未读';
  }

  @override
  String get feedMarkAllRead => '全部已读';

  @override
  String feedExpandChannel(String channel) {
    return '展开$channel';
  }

  @override
  String feedCollapseChannel(String channel) {
    return '收起$channel';
  }

  @override
  String get feedEmptyTitle => '暂无订阅更新';

  @override
  String get feedEmptyDescription => '关注的频道有新内容时会显示在这里';

  @override
  String get feedUnsupportedTitle => '该数据源暂不支持订阅动态';

  @override
  String get feedUpdateNotificationTitle => '订阅动态有更新';

  @override
  String feedUpdateNotificationBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '订阅动态有 $count 条新内容',
      one: '订阅动态有 1 条新内容',
    );
    return '$_temp0';
  }

  @override
  String get channelVideosUnsupported => '该数据源暂不支持频道视频';

  @override
  String get channelVideosEmpty => '暂无视频';

  @override
  String get channelTabPlaylists => '播放列表';

  @override
  String get channelPlaylistsEmpty => '暂无播放列表';

  @override
  String get sleepTimerActionExitPlayerLabel => '关闭播放器';

  @override
  String get sleepTimerDuration => '时长';

  @override
  String get sleepTimerEndingSoonTitle => '睡眠定时器';

  @override
  String get sleepTimerEndingSoonBody => '1 分钟后将停止播放';

  @override
  String get sleepTimerChannelName => '睡眠定时器';

  @override
  String get sleepTimerChannelDescription => '播放停止前一分钟提示';
}
