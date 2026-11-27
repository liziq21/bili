import 'package:material_ui/material_ui.dart';

/// 图标唯一来源（R9）。
///
/// `app/lib` 内只有本文件可以引用 `Icons.*`，其余代码一律经 [AppIcons] 取图标，
/// 由 `app/test/design/hardcoded_icon_test.dart` 强制。
///
/// 与 [AppColors] 不同，本类是静态常量命名空间而不是 `AppStyle` 的实例成员：
/// 图标不随亮度、动态色或屏幕尺寸变化，且 `IconData` 必须保持 `const` 才能让
/// `const Icon(...)` 继续成立——挂到 `$styles` 上会让所有图标失去编译期常量。
///
/// 命名按**含义**而非外观：可选中图标用 `x`（未选中，空心）/ `xSelected`
/// （选中，实心）成对声明（R10）。
abstract final class AppIcons() {
  // 导航。未选中空心、选中实心（R10）。
  static const IconData discover = Icons.explore_outlined;
  static const IconData discoverSelected = Icons.explore_rounded;
  static const IconData feed = Icons.rss_feed_outlined;
  static const IconData feedSelected = Icons.rss_feed_rounded;

  /// 搜索没有空心/实心两套字形，两个状态同值。
  static const IconData search = Icons.search_rounded;
  static const IconData searchSelected = Icons.search_rounded;
  static const IconData profile = Icons.person_outlined;
  static const IconData profileSelected = Icons.person_rounded;

  // 通用动作。
  static const IconData back = Icons.arrow_back_rounded;
  static const IconData chevronRight = Icons.chevron_right_rounded;
  static const IconData expandMore = Icons.expand_more_rounded;
  static const IconData dropDown = Icons.arrow_drop_down_rounded;
  static const IconData moreVert = Icons.more_vert_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData add = Icons.add_rounded;
  static const IconData check = Icons.check_rounded;
  static const IconData copy = Icons.copy_rounded;
  static const IconData refresh = Icons.refresh_rounded;
  static const IconData moveUp = Icons.arrow_upward_rounded;
  static const IconData moveDown = Icons.arrow_downward_rounded;
  static const IconData filter = Icons.filter_list_rounded;
  static const IconData dragHandle = Icons.drag_handle_rounded;
  static const IconData openInNew = Icons.open_in_new_rounded;

  // 状态与反馈。
  static const IconData error = Icons.error_outline_rounded;
  static const IconData searchOff = Icons.search_off_rounded;
  static const IconData cloudOff = Icons.cloud_off_rounded;
  static const IconData inbox = Icons.inbox_rounded;
  static const IconData history = Icons.history_rounded;
  static const IconData checkCircle = Icons.check_circle_rounded;
  static const IconData radioUnchecked = Icons.radio_button_unchecked_rounded;
  static const IconData verified = Icons.verified_rounded;
  static const IconData visibility = Icons.visibility_rounded;

  // 媒体与内容。
  static const IconData videoLibrary = Icons.video_library_rounded;
  static const IconData movie = Icons.movie_rounded;
  static const IconData liveTv = Icons.live_tv_rounded;
  static const IconData liveFeed = Icons.sensors_rounded;
  static const IconData queue = Icons.queue_music_outlined;
  static const IconData queueSelected = Icons.queue_music_rounded;
  static const IconData playlistAdd = Icons.playlist_add_rounded;
  static const IconData playlistPlay = Icons.playlist_play_rounded;
  static const IconData bookmark = Icons.bookmark_border_rounded;
  static const IconData bookmarkSelected = Icons.bookmark_rounded;
  static const IconData watchLater = Icons.watch_later_outlined;
  static const IconData watchLaterSelected = Icons.watch_later_rounded;
  static const IconData download = Icons.download_rounded;
  static const IconData downloaded = Icons.download_done_rounded;
  static const IconData gridView = Icons.grid_view_rounded;
  static const IconData calendar = Icons.calendar_month_rounded;
  static const IconData deleteSweep = Icons.delete_sweep_rounded;
  static const IconData playCircle = Icons.play_circle_outline_rounded;
  static const IconData playCircleFilled = Icons.play_circle_filled_rounded;
  static const IconData play = Icons.play_arrow_rounded;
  static const IconData pause = Icons.pause_rounded;
  static const IconData pauseCircle = Icons.pause_circle_filled_rounded;
  static const IconData skipPrevious = Icons.skip_previous_rounded;
  static const IconData skipNext = Icons.skip_next_rounded;
  static const IconData fastForward = Icons.fast_forward_rounded;
  static const IconData fastRewind = Icons.fast_rewind_rounded;
  static const IconData fullscreen = Icons.fullscreen_rounded;
  static const IconData fullscreenExit = Icons.fullscreen_exit_rounded;
  static const IconData pictureInPicture = Icons.picture_in_picture_alt_rounded;
  static const IconData equalizer = Icons.equalizer_rounded;
  static const IconData removeCircle = Icons.remove_circle_outline_rounded;
  static const IconData volumeOff = Icons.volume_off_rounded;
  static const IconData volumeLow = Icons.volume_down_rounded;
  static const IconData volumeHigh = Icons.volume_up_rounded;
  static const IconData brightness = Icons.brightness_6_rounded;

  // 播放模式。`off` 与 `loop` 必须是不同字形，否则用户无法从图标区分状态。
  static const IconData repeatOff = Icons.repeat_rounded;
  static const IconData repeatOne = Icons.repeat_one_rounded;
  static const IconData repeatQueue = Icons.repeat_on_rounded;

  // 互动。
  static const IconData like = Icons.thumb_up_outlined;
  static const IconData likeSelected = Icons.thumb_up_rounded;
  static const IconData favorite = Icons.star_border_rounded;
  static const IconData favoriteSelected = Icons.star_rounded;
  static const IconData share = Icons.share_outlined;
  static const IconData shareSelected = Icons.share_rounded;
  static const IconData comment = Icons.forum_rounded;
  static const IconData danmakuOn = Icons.subtitles_rounded;
  static const IconData danmakuOff = Icons.subtitles_off_rounded;
  static const IconData switchSource = Icons.sync_alt_rounded;
  static const IconData avatarFallback = Icons.person_rounded;
  static const IconData creator = Icons.person_outlined;
  static const IconData personAdd = Icons.person_add_alt_rounded;
  static const IconData viewers = Icons.people_alt_rounded;

  // 设置。
  static const IconData settings = Icons.settings_rounded;
  static const IconData palette = Icons.palette_outlined;
  static const IconData notifications = Icons.notifications_outlined;
  static const IconData tune = Icons.tune_rounded;

  /// 「设为首页主分区」：用图钉而不是星标——星标在本应用已表示收藏。
  static const IconData mainSection = Icons.push_pin_outlined;
  static const IconData mainSectionSelected = Icons.push_pin_rounded;

  // 首页分区与搜索来源。
  static const IconData sparkle = Icons.auto_awesome_rounded;
  static const IconData fire = Icons.local_fire_department_rounded;
  static const IconData hot = Icons.whatshot_rounded;
  static const IconData recommend = Icons.recommend_rounded;
  static const IconData web = Icons.public_rounded;
  static const IconData fillQuery = Icons.north_west_rounded;
}
