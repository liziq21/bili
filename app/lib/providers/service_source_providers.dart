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
  MediaSource? _createMediaSource(String sourceName) =>
      switch (sourceName.toLowerCase()) {
        'bilibili' => Bili(),
        'youtube' => YouTube(),
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    try {
      final currentSource = context.read<String?>();
      if (currentSource?.toLowerCase() == source.toLowerCase()) {
        return child;
      }
    } catch (_) {}

    final mediaSource = _createMediaSource(source);
    if (mediaSource == null) {
      return child;
    }

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
