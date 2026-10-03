import 'package:data/data.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../app_bloc.dart';
import '../app_scaffold.dart';
import '../data/repository/search_contents_repository.dart';
import '../data/repository/search_suggest_repository.dart';
import '../data/repository/video_detail_repository.dart';
import '../feature/home/bloc/home_bloc.dart';
import '../feature/media_library/media_history_cubit.dart';
import '../feature/search/bloc/search_bloc.dart';
import '../feature/search/bloc/search_result_bloc.dart';
import '../providers/service_source_providers.dart';
import '../providers/media_sources_provider.dart';
import '../ui/common/app_navigation_shell.dart';
import 'routes.dart';
import '../feature/home/home_screen.dart';
import '../feature/live/live_screen.dart';
import '../feature/media_library/media_library_screen.dart';
import '../feature/not_found/not_found_screen.dart';
import '../feature/search/search_result_screen.dart';
import '../feature/search/search_screen.dart';
import '../feature/space/space_screen.dart';
import '../feature/video/video_screen.dart';

part 'route_data/live_route_data.dart';
part 'route_data/not_found_route_data.dart';
part 'route_data/search_result_route_data.dart';
part 'route_data/space_route_data.dart';
part 'route_data/video_route_data.dart';
part 'router.g.dart';

String _resolveSource(BuildContext context) {
  // 未注册 String provider 时回落到配置的默认数据源，不在此处写死服务标识。
  try {
    final s = context.read<String?>();
    if (s != null) return s;
  } on ProviderNotFoundException {
    // 未注册，按默认数据源处理
  }
  return defaultMediaSources.first.id;
}

/// 底部导航目的地
///
/// 只列仓内已有数据支撑的三项。设计稿里的「订阅更新」与「我的」不做：前者需要
/// 订阅表（`database/table/` 无此表），后者需要登录（项目明确不实现登录），
/// 给出点开是空的导航项比不给更差。
List<AppNavDestination> get _navDestinations => [
  const AppNavDestination(label: '首页', icon: Icons.home_rounded),
  const AppNavDestination(
    label: '搜索',
    icon: Icons.search_rounded,
    railIcon: Icons.search_rounded,
  ),
  const AppNavDestination(
    label: '媒体资产',
    icon: Icons.video_library_rounded,
    railIcon: Icons.video_library_rounded,
  ),
];

final GoRouter router = GoRouter(
  // Security Hardening: Restrict diagnostic logging to non-release builds
  // to prevent leaking internal navigation traces, deep-link queries, and UI parameters.
  debugLogDiagnostics: !kReleaseMode,
  onException: (_, GoRouterState state, GoRouter router) {},
  routes: [
    // 底部导航的三个主分支。用 indexedStack 而非普通 ShellRoute：切分支时
    // 保留各分支的导航栈，从详情页返回时回到离开前的那一屏而不是分支根。
    StatefulShellRoute.indexedStack(
      builder:
          (
            context,
            state,
            navigationShell,
          ) => AppScaffold(
            child: AppNavigationShell(
              navigationShell: navigationShell,
              destinations: _navDestinations,
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
        $liveRouteData,
        $spaceRouteData,
        $videoRouteData,
        $searchRouteData,
        $notFoundRouteData,
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
  return BlocProvider<HomeBloc>(
    create: (context) => HomeBloc(
      userDataRepository: context.read(),
      mediaSources: context.read<List<MediaSource>>(),
    ),
    child: Builder(
      builder: (context) => BlocSelector<HomeBloc, HomeState, String>(
        selector: (state) => state.sourceId,
        builder: (context, sourceId) {
          // activeSource 会把不可用的 sourceId 回退到首个可用数据源，
          // 搜索建议必须跟着实际生效的数据源走。
          final effectiveSource =
              context.read<HomeBloc>().activeSource?.id ?? sourceId;

          return ServiceSourceProviders(
            source: effectiveSource,
            // 内层 Builder 的 context 位于 ServiceSourceProviders 之下，
            // 才能读到它注入的 SearchSuggestRepository。
            child: Builder(
              builder: (context) => _withSearchBloc(
                context,
                HomeScreen(
                  onLive: (roomId) {
                    final sourceId = context.read<HomeBloc>().activeSource?.id;
                    if (sourceId == null) return;
                    context.navigateToLive(roomId, source: sourceId);
                  },
                  navigateToSearchResult: (keyword) {
                    final sourceId = context.read<HomeBloc>().activeSource?.id;
                    if (sourceId == null) return;
                    context.navigateToSearchResult(keyword, source: sourceId);
                  },
                  onSpace: (mid) {
                    final sourceId = context.read<HomeBloc>().activeSource?.id;
                    if (sourceId == null) return;
                    context.navigateToSpace(mid, source: sourceId);
                  },
                  onVideo: (id) {
                    final sourceId = context.read<HomeBloc>().activeSource?.id;
                    if (sourceId == null) return;
                    context.navigateToVideo(id, source: sourceId);
                  },
                ),
              ),
            ),
          );
        },
      ),
    ),
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
    create: (context) => SearchBloc(
      searchSuggestRepository: context.read(),
      recentSearchQueryRepository: context.read(),
      getRentSearchQueriesUseCase: context.read(),
    ),
    child: child,
  );
}

/// 搜索分支
///
/// 数据源跟随 app 全局选择：用户的选择持久化在 [UserData]，首页由 HomeBloc 读它，
/// 搜索分支不在 HomeBloc 之下，因此自己从 [AppBloc] 读同一份数据再解析。
/// 少了这一步，用户在首页选了 YouTube、点进搜索页仍会搜 B 站。
Widget _buildSearchEntry(BuildContext context) {
  final persistedSourceId = context.select<AppBloc, String?>(
    (bloc) => switch (bloc.state) {
      LoadSuccess(:final userData) => userData.sourceId,
      _ => null,
    },
  );
  final sourceId = resolveMediaSourceId(
    context.read<List<MediaSource>>(),
    persistedSourceId,
  );
  return ServiceSourceProviders(
    source: sourceId,
    child: Builder(
      builder: (context) {
        // 建议能力依赖 SearchSuggestRepository。数据源不支持时（provider 未
        // 注入）不建 SearchBloc：它的构造器要三个必填依赖，硬建会拿到 null
        // 并在首次搜索时崩。
        if (context.read<SearchSuggestRepository?>() == null) {
          return SearchScreen(
            onSearch: (query) =>
                context.navigateToSearchResult(query, source: sourceId),
          );
        }
        return BlocProvider<SearchBloc>(
          create: (context) =>
              SearchBloc(
                searchSuggestRepository: context.read(),
                recentSearchQueryRepository: context.read(),
                getRentSearchQueriesUseCase: context.read(),
              )
              // 建 bloc 后立刻订阅最近搜索，否则历史列表不会自己更新。
              ..add(MonitorRecentSearches()),
          child: SearchScreen(
            onSearch: (query) =>
                context.navigateToSearchResult(query, source: sourceId),
          ),
        );
      },
    ),
  );
}

/// 媒体资产分支
Widget _buildLibrary(BuildContext context) {
  return BlocProvider<MediaHistoryCubit>(
    create: (context) => MediaHistoryCubit(mediaHistoryDao: context.read()),
    // 回调必须在 provider 之下创建：它读的是承载列表与分页的那个 cubit，用 provider
    // 之上的 context 去 read 会抛 ProviderNotFoundException。
    child: Builder(
      builder: (context) => MediaLibraryScreen(
        onVideoTap: (item) => context.navigateToVideo(
          item.video.id,
          // 历史跨源存放，不带 source 会落到当前默认源，用错源的接口取详情会失败。
          source: item.sourceId,
        ),
      ),
    ),
  );
}
