import '../../l10n/localization_file/app_localizations.dart';

/// 搜索结果页可用的结果类型。
///
/// 播放列表没有可用的搜索端点：B 站 `search_type` 不含 playlist，YouTube
/// InnerTube 的 playlist 内容类型也没有对应的结果模型。因此枚举保留该类型
/// 以便将来接入，但结果页不会为它挂空 tab。
enum SearchResultType() {
  all,
  video,
  channel,
  live,
  playlist;

  String label(AppLocalizations? l10n) => switch (this) {
    .all => l10n?.searchResultTypeAll ?? 'All',
    .video => l10n?.searchResultTypeVideo ?? 'Videos',
    .channel => l10n?.searchResultTypeChannel ?? 'Channels',
    .live => l10n?.searchResultTypeLive ?? 'Live',
    .playlist => l10n?.searchResultTypePlaylist ?? 'Playlists',
  };
}
