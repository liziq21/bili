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
  /// 根据数据源标识字符串创建对应的 [MediaSource] 实例
  ///
  /// 未知标识直接抛错而非返回 null：返回 null 会让子树在缺少 Repository 的情况下
  /// 继续构建，错误改到离病因很远的 `context.read<...>()` 才暴露成
  /// ProviderNotFoundException，无法回溯到是哪个标识没被注册。
  MediaSource _createMediaSource(String sourceName) =>
      switch (sourceName.toLowerCase()) {
        'bilibili' => Bili(),
        'youtube' => YouTube(),
        _ => throw ArgumentError.value(
          sourceName,
          'sourceName',
          '未知数据源标识（已注册：bilibili、youtube）',
        ),
      };

  @override
  Widget build(BuildContext context) {
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
