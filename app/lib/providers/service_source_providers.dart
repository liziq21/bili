import 'package:bilibili/bilibili.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:model/model.dart';
import 'package:youtube/youtube.dart';

import '../data/repository/search/app_live_room_search_repository.dart';
import '../data/repository/search/app_user_search_repository.dart';
import '../data/repository/search/app_video_search_repository.dart';
import '../data/repository/search/app_youtube_video_search_repository.dart';
import '../data/repository/search_contents_repository.dart';
import '../data/repository/search_suggest_repository.dart';

class ServiceSourceProviders extends StatelessWidget {
  const ServiceSourceProviders({
    super.key,
    required this.source,
    required this.child,
  });

  final ServiceSource source;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    try {
      final currentSource = context.read<ServiceSource?>();
      if (currentSource == source) {
        return child;
      }
    } catch (_) {
    }

    return RepositoryProvider<ServiceSource>.value(
      value: source,
      child: switch (source) {
        ServiceSource.bilibili => MultiRepositoryProvider(
            providers: [
              RepositoryProvider<Bili>(
                create: (_) => Bili(),
                dispose: (bili) => bili.close(),
              ),
              RepositoryProvider<VideoSearchRepository>(
                create: (context) => AppVideoSearchRepository(
                  context.read<Bili>().videoSearchDataSource(),
                ),
              ),
              RepositoryProvider<CreatorProfileSearchRepository>(
                create: (context) => AppUserSearchRepository(
                  context.read<Bili>().creatorProfileSearchDataSource(),
                  context.read<Bili>().searchSuggestDataSource(),
                ),
              ),
              RepositoryProvider<LiveRoomSearchRepository>(
                create: (context) => AppLiveRoomSearchRepository(
                  context.read<Bili>().liveRoomSearchDataSource(),
                ),
              ),
              RepositoryProvider<SearchSuggestRepository>(
                create: (context) => AppUserSearchRepository(
                  context.read<Bili>().creatorProfileSearchDataSource(),
                  context.read<Bili>().searchSuggestDataSource(),
                ),
              ),
            ],
            child: child,
          ),
        ServiceSource.youtube => MultiRepositoryProvider(
            providers: [
              RepositoryProvider<YouTube>(
                create: (_) => YouTube(),
                dispose: (yt) => yt.close(),
              ),
              RepositoryProvider<VideoSearchRepository>(
                create: (context) => AppYouTubeVideoSearchRepository(
                  context.read<YouTube>().videoSearchDataSource(),
                ),
              ),
            ],
            child: child,
          ),
      },
    );
  }
}
