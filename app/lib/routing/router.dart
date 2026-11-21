import 'package:data/data.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../design/design.dart';
import '../l10n/localization_file/app_localizations.dart';
import '../app_bloc.dart';
import '../app_scaffold.dart';
import '../data/repository/search_contents_repository.dart';
import '../data/repository/search_suggest_repository.dart';
import '../data/repository/video_detail_repository.dart';
import '../datastore/preferences_data_source.dart';
import '../domain/feed_load_manager.dart';
import '../feature/feed/feed_cubit.dart';
import '../feature/feed/feed_screen.dart';
import '../feature/home/bloc/home_bloc.dart';
import '../feature/media_library/media_history_cubit.dart';
import '../feature/media_library/local_library_screen.dart';
import '../feature/not_found/no_media_source_screen.dart';
import '../feature/notification/feed_notification_listener.dart';
import '../feature/search/bloc/search_bloc.dart';
import '../feature/search/bloc/search_result_bloc.dart';
import '../providers/service_source_providers.dart';
import '../providers/media_sources_provider.dart';
import '../ui/common/app_navigation_shell.dart';
import 'routes.dart';
import 'search_focus_controller.dart';
import '../feature/home/home_config_editor_screen.dart';
import '../feature/home/home_screen.dart';
import '../feature/live/live_screen.dart';
import '../feature/media_library/media_library_screen.dart';
import '../feature/not_found/not_found_screen.dart';
import '../feature/playlist/playlist_screen.dart';
import '../feature/search/search_result_screen.dart';
import '../feature/search/search_screen.dart';
import '../feature/setting/advanced_settings_screen.dart';
import '../feature/setting/appearance_settings_screen.dart';
import '../feature/setting/channel_settings_screen.dart';
import '../feature/setting/history_settings_screen.dart';
import '../feature/setting/library_settings_screen.dart';
import '../feature/setting/notification_settings_screen.dart';
import '../feature/setting/player_settings_screen.dart';
import '../feature/setting/setting_screen.dart';
import '../feature/space/space_screen.dart';
import '../feature/video/video_screen.dart';
import '../feature/video/video_queue_request.dart';
import '../feature/video/danmaku/danmaku_settings_screen.dart';

part 'route_data/live_route_data.dart';
part 'route_data/not_found_route_data.dart';
part 'route_data/playlist_route_data.dart';
part 'route_data/search_result_route_data.dart';
part 'route_data/space_route_data.dart';
part 'route_data/video_route_data.dart';
part 'router.g.dart';

extension NavigationCallbacks on BuildContext {
  /// 默认视频导航：读取当前作用域的 MediaSource
  void defaultNavigateToVideo(String videoId) {
    final source = read<MediaSource>();
    navigateToVideo(videoId, source: source.id);
  }

  /// 默认直播导航
  void defaultNavigateToLive(String roomId) {
    final source = read<MediaSource>();
    navigateToLive(roomId, source: source.id);
  }

  /// 默认空间导航
  void defaultNavigateToSpace(String mid) {
    final source = read<MediaSource>();
    navigateToSpace(mid, source: source.id);
  }

  /// 默认搜索导航
  void defaultNavigateToSearchResult(String query) {
    final source = read<MediaSource>();
    navigateToSearchResult(query, source: source.id);
  }

  /// 默认创作者导航（媒体库）
  void defaultNavigateToCreator(String sourceId, String creatorId) {
    navigateToSpace(creatorId, source: sourceId);
  }

  /// 默认视频导航（媒体库）
  void defaultNavigateToMediaLibraryVideo(String sourceId, String videoId) {
    navigateToVideo(videoId, source: sourceId);
  }
}

/// 搜索分支输入框的聚焦入口改为 [SearchFocusController]
///
/// 底栏重复点「搜索」时用它：已经在搜索页就把焦点交回输入框，让用户直接继续
/// 打字。控制器由 [StatefulShellRoute.indexedStack] 的 builder 以
/// [ChangeNotifierProvider] 注入，导航目的地（[_navDestinations]）与搜索页因此
/// 共享同一实例——不再依赖顶层可变闭包，多实例与测试之间不会互相污染。

/// 解析当前路由作用域内生效的数据源定义
///
/// 显式 source 优先；其次读 [ServiceSourceProviders] 注入的
/// [MediaSourceDefinition]；最后回退到 [AppBloc] 里持久化的选择。供根级推入页面
/// （视频 / 直播 / 空间 / 搜索结果 / 播放列表）在组装自己的源作用域前调用。
MediaSourceDefinition? _resolveSource(
  BuildContext context, {
  String? explicitSource,
}) {
  final catalog = context.read<MediaSourceCatalog>();
  if (explicitSource != null) return catalog.find(explicitSource);

  try {
    final scopedSource = context.read<MediaSourceDefinition?>();
    if (scopedSource != null) return scopedSource;
  } on ProviderNotFoundException {
    // The route is not below a source scope yet.
  }

  final appBloc = context.read<AppBloc?>();
  final persistedSource = switch (appBloc?.state) {
    LoadSuccess(:final userData) => userData.sourceId,
    _ => null,
  };
  return catalog.resolvePersisted(persistedSource);
}

/// 底部导航目的地
///
/// 只列仓内已有数据支撑的四项：首页 / 订阅动态 / 搜索 / 我的。订阅动态读
/// `feed_entry` 表（[FeedLoadManager] 落库），数据源不提供频道投稿能力时
/// 页面给出「该数据源暂不支持订阅动态」，而不是给一个点开就崩的导航项。
List<AppNavDestination> _navDestinations(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return [
    AppNavDestination(
      label: l10n?.navHomeLabel ?? 'Home',
      icon: AppIcons.home,
      selectedIcon: AppIcons.homeSelected,
    ),
    AppNavDestination(
      label: l10n?.feedTitle ?? 'Subscription feed',
      icon: AppIcons.feed,
      selectedIcon: AppIcons.feedSelected,
    ),
    AppNavDestination(
      label: l10n?.search ?? 'Search',
      icon: AppIcons.search,
      selectedIcon: AppIcons.searchSelected,
      // 已在搜索分支时再点搜索，把焦点交回输入框而不是把页面重置一遍。
      onReselect: () => context.read<SearchFocusController>().requestFocus(),
    ),
    AppNavDestination(
      label: l10n?.mine ?? 'Mine',
      icon: AppIcons.profile,
      selectedIcon: AppIcons.profileSelected,
    ),
  ];
}

final _log = Logger('Router');

/// 安全脱敏的纯函数：只保留 URI 的 path（剥离 query / fragment / user-info），
/// 并去掉控制字符。抽出为纯函数是为了让脱敏规则可被单测直接验证——
/// [logRoutingException] 的 logger 是模块级单例，测试无法只观测单次调用。
String sanitizedRoutingPath(GoRouterState state) =>
    NotFoundScreen.sanitizeUriString(state.uri.path);

/// Logs routing exceptions with path-only diagnostics.
///
/// The URI path is retained for debugging, while query parameters, fragments,
/// authority/user-info, and the exception payload are intentionally omitted.
void logRoutingException(GoRouterState state) {
  _log.severe('Routing exception for path: ${sanitizedRoutingPath(state)}');
}

final GoRouter router = GoRouter(
  // Security Hardening: Restrict diagnostic logging to non-release builds
  // to prevent leaking internal navigation traces, deep-link queries, and UI parameters.
  debugLogDiagnostics: !kReleaseMode,
  onException: (_, GoRouterState state, GoRouter router) {
    logRoutingException(state);
  },
  routes: [
    // 底部导航的四个主分支。用 indexedStack 而非普通 ShellRoute：切分支时
    // 保留各分支的导航栈，从详情页返回时回到离开前的那一屏而不是分支根。
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => ChangeNotifierProvider(
        create: (_) => SearchFocusController(),
        child: FeedNotificationListener(
          child: Builder(
            builder: (context) => AppScaffold(
              child: AppNavigationShell(
                navigationShell: navigationShell,
                destinations: _navDestinations(context),
              ),
            ),
          ),
        ),
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.home,
              builder: (context, state) => _buildHome(context),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.feed,
              builder: (context, state) => _buildFeed(context),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.searchEntry,
              builder: (context, state) => _buildSearchEntry(context),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.library,
              builder: (context, state) => _buildLibrary(context),
            ),
          ],
        ),
      ],
    ),

    // 根级路由：从任意页面推入的次级页面（视频详情 / 直播 / 空间 / 搜索结果 /
    // 404），覆盖在导航骨架之上，不出现在底栏里。搜索结果页放在这里而不是挂成
    // 首页分支的子路由：它是推入的次级页面，从搜索分支提交时不应把底栏高亮带回
    // 首页分支，退栈后也应回到搜索入口而不是首页。
    ShellRoute(
      builder: (_, _, navigator) {
        return AppScaffold(child: navigator);
      },
      routes: [
        ...$appRoutes,
        GoRoute(
          path: Routes.settings,
          builder: (context, _) => SettingScreen(
            onBackClick: () => context.pop(),
            onSectionSelected: (section) =>
                context.push<void>(switch (section) {
                  SettingsSection.player => Routes.settingsPlayer,
                  SettingsSection.appearance => Routes.settingsAppearance,
                  SettingsSection.history => Routes.settingsHistory,
                  SettingsSection.library => Routes.settingsLibrary,
                  SettingsSection.notifications => Routes.settingsNotifications,
                  SettingsSection.advanced => Routes.settingsAdvanced,
                  SettingsSection.discovery => Routes.settingsDiscovery,
                  SettingsSection.channel => Routes.settingsChannel,
                }),
          ),
          routes: [
            GoRoute(
              path: Routes.settingsPlayerRelative,
              builder: (_, _) => const PlayerSettingsScreen(),
            ),
            GoRoute(
              path: Routes.settingsAppearanceRelative,
              builder: (_, _) => const AppearanceSettingsScreen(),
            ),
            GoRoute(
              path: Routes.settingsHistoryRelative,
              builder: (_, _) => const HistorySettingsScreen(),
            ),
            GoRoute(
              path: Routes.settingsLibraryRelative,
              builder: (_, _) => const LibrarySettingsScreen(),
            ),
            GoRoute(
              path: Routes.settingsNotificationsRelative,
              builder: (_, _) => const NotificationSettingsScreen(),
            ),
            GoRoute(
              path: Routes.settingsAdvancedRelative,
              builder: (_, _) => const AdvancedSettingsScreen(),
            ),
            GoRoute(
              path: Routes.settingsDiscoveryRelative,
              builder: (_, _) => const HomeConfigEditorScreen(),
            ),
            GoRoute(
              path: Routes.settingsChannelRelative,
              builder: (_, _) => const ChannelSettingsScreen(),
            ),
          ],
        ),
        GoRoute(
          path: Routes.danmakuSettings,
          builder: (_, _) => const DanmakuSettingsScreen(),
        ),
      ],
    ),
  ],
  initialLocation: Routes.home,
);

/// 首页分支
///
/// 原 `HomeRouteData.build` 的内容搬到这里：它把 HomeBloc 的 sourceId 解析、
/// `ServiceSourceProviders` 注入与搜索 bloc 注入串在一起，属于「组装」而不是
/// 「路由声明」，放在路由数据类里会让人误以为换个路由就得复制这段。
Widget _buildHome(BuildContext context) {
  return _ScopedSourceBuilder(
    keyPrefix: 'home',
    builder: (context) => BlocProvider<HomeBloc>(
      create: (context) => HomeBloc(
        userDataRepository: context.read(),
        preferences: context.read<PreferencesDataSource?>(),
        source: context.read<MediaSource>(),
        // 数据源不支持频道投稿时不注入，HomeBloc 跳过订阅增量加载。
        feedLoadManager: context.read<FeedLoadManager?>(),
      ),
      child: Builder(
        builder: (context) => _withSearchBloc(
          context,
          HomeScreen(
            onSettings: () => context.push<void>(Routes.settings),
            onLive: context.defaultNavigateToLive,
            onVideo: context.defaultNavigateToVideo,
          ),
        ),
      ),
    ),
  );
}

/// 订阅动态分支
///
/// 与首页共用 [_ScopedSourceBuilder]：两个分支都从 [AppBloc] 的
/// `userData.sourceId` 解析源目录。`FeedCubit` 直接读 [FeedDao] 与
/// [LocalLibraryDao]（顶层 provider 注入），不依赖数据源实例；只有刷新时
/// 用到的 [FeedLoadManager] 是可选能力，数据源不提供频道投稿时页面显示
/// 「该数据源暂不支持订阅动态」。
Widget _buildFeed(BuildContext context) {
  return _ScopedSourceBuilder(
    keyPrefix: 'feed',
    builder: (context) {
      final source = context.read<MediaSource>();
      return BlocProvider<FeedCubit>(
        create: (context) => FeedCubit(
          feedDao: context.read(),
          libraryDao: context.read(),
          sourceId: source.id,
          feedLoadManager: context.read<FeedLoadManager?>(),
        ),
        child: FeedScreen(
          onVideo: context.defaultNavigateToVideo,
          sourceSupportsFeed: source.userVideosDataSource != null,
        ),
      );
    },
  );
}

/// 首页搜索入口复用 [SearchBloc] 提供联想建议；数据源没有建议能力时直接返回
/// 原 child，让 AppBar 隐藏搜索入口，而不是在缺少 bloc 时崩溃。
///
/// 必须在 [ServiceSourceProviders] 之下调用，否则读不到它注入的
/// [SearchSuggestRepository]。
Widget _withSearchBloc(BuildContext context, Widget child) {
  if (context.read<SearchSuggestRepository?>() == null) return child;

  return BlocProvider<SearchBloc>(
    create: (context) =>
        SearchBloc(
            searchSuggestRepository: context.read(),
            recentSearchQueryRepository: context.read(),
            getRentSearchQueriesUseCase: context.read(),
            preferences: context.read<PreferencesDataSource>(),
          )
          // 建 bloc 后立刻订阅最近搜索，否则历史列表不会自己更新。
          ..add(MonitorRecentSearches()),
    child: child,
  );
}

/// 搜索分支
///
/// 数据源跟随 app 全局选择：用户的选择持久化在 [UserData]，搜索分支从同一份
/// 状态解析源目录。源实例仍由本分支的 [ServiceSourceProviders] 创建并拥有。
Widget _buildSearchEntry(BuildContext context) {
  return _ScopedSourceBuilder(
    keyPrefix: 'search',
    builder: (context) {
      // 建议能力依赖 SearchSuggestRepository。数据源不支持时（provider 未
      // 注入）不建 SearchBloc：它的构造器要三个必填依赖，硬建会拿到 null
      // 并在首次搜索时崩。
      return _withSearchBloc(
        context,
        SearchScreen(
          onFocusInputReady: context.read<SearchFocusController?>()?.register,
          onSearch: context.defaultNavigateToSearchResult,
        ),
      );
    },
  );
}

/// 解析当前持久化的数据源并把 [ServiceSourceProviders] 注入子树。
///
/// 首页与搜索分支共用：两者都从 [AppBloc] 的 `userData.sourceId` 解析源目录，
/// 无可用源时渲染 [NoMediaSourceScreen]。`keyPrefix` 让两个分支各自的
/// [ServiceSourceProviders] 拿到不同的 [ValueKey]，切换数据源时子树按分支重建。
class const _ScopedSourceBuilder({
  required final String keyPrefix,
  required final WidgetBuilder builder,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocSelector<AppBloc, AppState, String?>(
      selector: (state) => switch (state) {
        LoadSuccess(:final userData) => userData.sourceId,
        _ => null,
      },
      builder: (context, persistedSourceId) {
        final definition = context.read<MediaSourceCatalog>().resolvePersisted(
          persistedSourceId,
        );
        if (definition == null) return const NoMediaSourceScreen();

        return ServiceSourceProviders(
          key: ValueKey('$keyPrefix:${definition.id}'),
          source: definition.id,
          child: Builder(builder: builder),
        );
      },
    );
  }
}

/// 媒体资产分支
Widget _buildLibrary(BuildContext context) {
  return LocalLibraryScreen(
    history: BlocProvider<MediaHistoryCubit>(
      create: (context) => MediaHistoryCubit(mediaHistoryDao: context.read()),
      // 回调必须在 provider 之下创建：它读的是承载列表与分页的那个 cubit，用 provider
      // 之上的 context 去 read 会抛 ProviderNotFoundException。
      child: Builder(
        builder: (context) => MediaLibraryScreen(
          onVideoTap: context.defaultNavigateToMediaLibraryVideo,
        ),
      ),
    ),
    onVideoTap: context.defaultNavigateToMediaLibraryVideo,
    onCreatorTap: context.defaultNavigateToCreator,
    onPlayPlaylist: (sourceId, videoIds, {required startIndex}) =>
        context.navigateToPlaylistQueue(
          source: sourceId,
          videoIds: videoIds,
          startIndex: startIndex,
        ),
  );
}
