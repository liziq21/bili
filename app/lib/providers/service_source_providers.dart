import 'package:bilibili/bilibili.dart';
import 'package:data/data.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:youtube/youtube.dart';

import '../data/repository/search/app_live_room_search_repository.dart';
import '../data/repository/search/app_user_search_repository.dart';
import '../data/repository/search/app_video_search_repository.dart';
import '../data/repository/search/app_youtube_video_search_repository.dart';
import '../data/repository/search_contents_repository.dart';
import '../data/repository/search_suggest_repository.dart';
import '../data/repository/video_comment_repository.dart';
import '../data/repository/video_detail_repository.dart';

/// 数据源 Context 依赖注入提供器 (Service Source Provider)
///
/// 当导航到特定数据源页面（如 Bilibili 或 YouTube）时，
/// 负责为组件树条件注入该数据源实例及其实现的相关 Repository。
class const ServiceSourceProviders({
  super.key,

  /// 数据源标识名称（如 'bilibili', 'youtube'）
  required final String source,

  /// 子组件
  required final Widget child,
}) extends StatelessWidget {
  /// 已注册数据源标识 → 实例构造函数。新增数据源在此登记一处。
  ///
  /// 用构造函数 tear-off 而非已建实例：校验只需查表，不必每次 build 都 new
  /// 一个 [Bili]/[YouTube]（`Bili` 的生命周期由下方 `dispose` 负责关闭）。
  static const _registry = <String, MediaSource Function()>{
    'bilibili': Bili.new,
    'youtube': YouTube.new,
  };

  /// 未注册标识直接抛错，不静默放过。
  ///
  /// 必须在任何提前返回 `child` 之前调用：[source] 是公开构造参数，若祖先已
  /// 注册了同名 String provider，校验会被 `return child` 绕过。
  void _assertRegistered(String sourceName) {
    if (!_registry.containsKey(sourceName.toLowerCase())) {
      throw ArgumentError.value(
        sourceName,
        'sourceName',
        '未知数据源标识（已注册：${_registry.keys.join('、')}）',
      );
    }
  }

  /// 根据数据源标识字符串创建对应的 [MediaSource] 实例
  MediaSource _createMediaSource(String sourceName) =>
      _registry[sourceName.toLowerCase()]!();

  @override
  Widget build(BuildContext context) {
    // 先校验再谈其它：未注册标识必须在建树前暴露，否则错误会推迟到子树里
    // 某处 `context.read<...>()` 抛出 ProviderNotFoundException 而无法回溯来源。
    _assertRegistered(source);

    // 仅「String provider 未注册」时按需注入；其它异常不得吞掉。
    String? currentSource;
    try {
      currentSource = context.read<String?>();
    } on ProviderNotFoundException {
      currentSource = null;
    }
    if (currentSource?.toLowerCase() == source.toLowerCase()) {
      return child;
    }

    final mediaSource = _createMediaSource(source);

    return RepositoryProvider<String>.value(
      value: source,
      child: RepositoryProvider<MediaSource>.value(
        value: mediaSource,
        child: switch (source.toLowerCase()) {
          'bilibili' => MultiRepositoryProvider(
            providers: [
              RepositoryProvider<Bili>(
                create: (_) => mediaSource as Bili,
                dispose: (bili) => bili.close(),
              ),
              RepositoryProvider<VideoSearchRepository>(
                create: (context) => AppVideoSearchRepository(
                  context.read<Bili>().videoSearchDataSource,
                ),
              ),
              RepositoryProvider<CreatorProfileSearchRepository>(
                create: (context) => AppUserSearchRepository(
                  context.read<Bili>().creatorProfileSearchDataSource,
                  context.read<Bili>().searchSuggestDataSource,
                ),
              ),
              RepositoryProvider<LiveRoomSearchRepository>(
                create: (context) => AppLiveRoomSearchRepository(
                  context.read<Bili>().liveRoomSearchDataSource,
                ),
              ),
              RepositoryProvider<SearchSuggestRepository>(
                create: (context) => AppUserSearchRepository(
                  context.read<Bili>().creatorProfileSearchDataSource,
                  context.read<Bili>().searchSuggestDataSource,
                ),
              ),
              RepositoryProvider<VideoDetailRepository>(
                create: (context) => AppVideoDetailRepository(
                  context.read<Bili>().videoDetailDataSource,
                ),
              ),
              RepositoryProvider<VideoCommentRepository>(
                create: (context) => AppVideoCommentRepository(
                  context.read<Bili>().videoCommentDataSource,
                ),
              ),
            ],
            child: child,
          ),
          'youtube' => MultiRepositoryProvider(
            providers: [
              RepositoryProvider<YouTube>(
                create: (_) => mediaSource as YouTube,
                dispose: (yt) => yt.close(),
              ),
              RepositoryProvider<VideoSearchRepository>(
                create: (context) => AppYouTubeVideoSearchRepository(
                  context.read<YouTube>().videoSearchDataSource,
                ),
              ),
            ],
            child: child,
          ),
          _ => child,
        },
      ),
    );
  }
}
