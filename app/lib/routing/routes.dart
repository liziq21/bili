abstract final class Routes() {
  static const notFound = '/404';
  static const home = '/';
  static const live = '/$liveRelative';
  static const liveRelative = 'live';
  static const search = '/$searchRelative';
  static const searchRelative = 'search';

  /// 底部导航的搜索入口页
  ///
  /// 与 [search]（搜索结果页，路径需带 keyword）分开：结果页是从任意页面推入
  /// 的次级页面，底栏分支不能指向一个缺参数就构建不出来的路由。
  static const searchEntry = '/$searchEntryRelative';
  static const searchEntryRelative = 'search_entry';

  /// 底部导航的媒体资产页
  static const library = '/$libraryRelative';
  static const libraryRelative = 'library';

  static const settings = '/settings';
  static const settingsPlayerRelative = 'player';
  static const settingsPlayer = '$settings/$settingsPlayerRelative';
  static const settingsAppearanceRelative = 'appearance';
  static const settingsAppearance = '$settings/$settingsAppearanceRelative';
  static const settingsHistoryRelative = 'history';
  static const settingsHistory = '$settings/$settingsHistoryRelative';
  static const settingsLibraryRelative = 'library';
  static const settingsLibrary = '$settings/$settingsLibraryRelative';
  static const settingsAdvancedRelative = 'advanced';
  static const settingsAdvanced = '$settings/$settingsAdvancedRelative';

  static const danmakuSettings = '$settings/danmaku';

  static const space = '/$spaceRelative';
  static const spaceRelative = 'space';
  static const video = '/$videoRelative';
  static const videoRelative = 'video';

  static String videoWithId(String id) => '$video/$id';
}
