import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:data/data.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';

import '../../data/repository/channel_videos_repository.dart';
import '../../data/repository/creator_profile_repository.dart';
import '../../design/design.dart';
import '../../l10n/localization_file/app_localizations.dart';
import '../../l10n/localization_file/app_localizations_zh.dart';
import '../../main.dart';
import '../../routing/navigation_callbacks.dart';
import '../../ui/video_card.dart';
import 'bloc/channel_videos_cubit.dart';

class const SpaceScreen({
  super.key,
  final VoidCallback? onBackClick,
  final VideoNavCallback? onVideo,
  required final String mid,
}) extends StatefulWidget {
  @override
  State<SpaceScreen> createState() => _SpaceScreenState();
}

class _SpaceScreenState() extends State<SpaceScreen> {
  CreatorProfileRepository? _repository;
  Future<Result<CreatorProfile, Exception>>? _profileFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = context.read<CreatorProfileRepository?>();
    if (_profileFuture != null && identical(repository, _repository)) return;

    _repository = repository;
    _profileFuture = _loadProfile();
  }

  @override
  void didUpdateWidget(covariant SpaceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mid == widget.mid) return;
    _profileFuture = _loadProfile();
  }

  Future<Result<CreatorProfile, Exception>> _loadProfile() {
    final repository = _repository;
    if (repository == null) {
      return Future.value(
        Result.error(Exception('Creator profile source unavailable')),
      );
    }
    return repository.getProfile(widget.mid);
  }

  void _retry() {
    setState(() {
      _profileFuture = _loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Keep the route subtree subscribed to brightness changes because `$styles`
    // is a mutable singleton refreshed by AppScaffold.
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();

    return Scaffold(
      appBar: AppBar(
        leading: widget.onBackClick == null
            ? null
            : IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onBackClick?.call();
                },
                tooltip: l10n.back,
                icon: const Icon(AppIcons.back),
              ),
        title: Text(l10n.creatorTab),
      ),
      body: FutureBuilder<Result<CreatorProfile, Exception>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: CircularProgressIndicator(
                color: $styles.colors.accentFill,
              ),
            );
          }

          if (snapshot.hasError || snapshot.data == null) {
            return _ProfileLoadError(onRetry: _retry);
          }

          return switch (snapshot.data!) {
            Success(:final success) => _SpaceContent(
              profile: success,
              mid: widget.mid,
              colorScheme: colorScheme,
              onVideo: widget.onVideo,
            ),
            Error() => _ProfileLoadError(onRetry: _retry),
          };
        },
      ),
    );
  }
}

/// 资料头 + 内容 tab。
///
/// tab 按数据源真实能力生成：当前只有「视频」有频道级端点，直播 / 短视频 /
/// 播放列表没有可用的频道列表接口，因此不挂空 tab。
class const _SpaceContent({
  required final CreatorProfile profile,
  required final String mid,
  required final ColorScheme colorScheme,
  required final VideoNavCallback? onVideo,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    final videosRepository = context.read<ChannelVideosRepository?>();
    final tabBar = TabBar(
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      onTap: (_) => HapticFeedback.selectionClick(),
      tabs: [Tab(text: l10n.videoTab)],
    );
    final tabBarHeight = _tabBarHeight(context);

    return DefaultTabController(
      length: 1,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: _CreatorProfileHeader(
              profile: profile,
              colorScheme: colorScheme,
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _ChannelTabBar(tabBar: tabBar, height: tabBarHeight),
          ),
        ],
        body: TabBarView(
          children: [
            if (videosRepository == null)
              const _ChannelVideosUnsupported()
            else
              BlocProvider<ChannelVideosCubit>(
                create: (_) => ChannelVideosCubit(videosRepository, mid),
                child: _ChannelVideosGrid(onVideo: onVideo),
              ),
          ],
        ),
      ),
    );
  }
}

double _tabBarHeight(BuildContext context) {
  final textScaler = MediaQuery.textScalerOf(context);
  final content =
      textScaler.scale($styles.text.bodySmall.fontSize ?? 14) * 1.4 +
      $styles.insets.xs * 2;
  return content < kTextTabBarHeight ? kTextTabBarHeight : content;
}

class const _ChannelTabBar({
  required final TabBar tabBar,
  required final double height,
}) extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => Material(
    color: Theme.of(context).colorScheme.surface,
    elevation: overlapsContent ? 2 : 0,
    child: SizedBox(height: height, child: tabBar),
  );

  @override
  bool shouldRebuild(_ChannelTabBar oldDelegate) =>
      oldDelegate.tabBar != tabBar || oldDelegate.height != height;
}

/// 频道投稿分页网格。
class const _ChannelVideosGrid({required final VideoNavCallback? onVideo})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChannelVideosCubit, PagingState<int, VideoModel>>(
      builder: (context, state) => CustomScrollView(
        slivers: [
          PagedSliverGrid<int, VideoModel>(
            state: state,
            fetchNextPage: () =>
                context.read<ChannelVideosCubit>().fetchNextPage(),
            builderDelegate: PagedChildBuilderDelegate<VideoModel>(
              itemBuilder: (context, video, index) => VideoCard(
                key: ValueKey(video.id),
                videoInfoBase: video,
                onTap: onVideo == null ? null : () => onVideo?.call(video.id),
              ),
              firstPageProgressIndicatorBuilder: (context) => Center(
                child: CircularProgressIndicator(
                  color: $styles.colors.accentFill,
                ),
              ),
              firstPageErrorIndicatorBuilder: (context) =>
                  const _ChannelVideosError(),
              newPageErrorIndicatorBuilder: (context) =>
                  const _ChannelVideosPageError(),
              noItemsFoundIndicatorBuilder: (context) =>
                  const _ChannelVideosEmpty(),
            ),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              mainAxisSpacing: $styles.insets.sm,
              crossAxisSpacing: $styles.insets.sm,
              childAspectRatio: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class const _ChannelVideosError() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.error, color: $styles.colors.outline),
          SizedBox(height: $styles.insets.xs),
          Text(
            l10n.loadFailedRetryLater,
            textAlign: TextAlign.center,
            style: $styles.text.body.copyWith(
              color: $styles.colors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: $styles.insets.xs),
          FilledButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              context.read<ChannelVideosCubit>().fetchNextPage();
            },
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}

class const _ChannelVideosPageError() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    return Padding(
      padding: EdgeInsets.all($styles.insets.sm),
      child: Center(
        child: TextButton.icon(
          onPressed: () {
            HapticFeedback.lightImpact();
            context.read<ChannelVideosCubit>().fetchNextPage();
          },
          icon: const Icon(AppIcons.refresh, size: 18),
          label: Text(l10n.moreLoadFailedRetry),
        ),
      ),
    );
  }
}

class const _ChannelVideosEmpty() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.videoLibrary, color: $styles.colors.outline),
          SizedBox(height: $styles.insets.xs),
          Text(
            l10n.channelVideosEmpty,
            style: $styles.text.body.copyWith(
              color: $styles.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class const _ChannelVideosUnsupported() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    return Center(
      child: Padding(
        padding: EdgeInsets.all($styles.insets.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.videoLibrary, color: $styles.colors.outline),
            SizedBox(height: $styles.insets.xs),
            Text(
              l10n.channelVideosUnsupported,
              textAlign: TextAlign.center,
              style: $styles.text.body.copyWith(
                color: $styles.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class const _ProfileLoadError({required final VoidCallback onRetry})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    return Center(
      child: Padding(
        padding: EdgeInsets.all($styles.insets.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.error, color: $styles.colors.outline),
            SizedBox(height: $styles.insets.xs),
            Text(
              l10n.loadFailedRetryLater,
              textAlign: TextAlign.center,
              style: $styles.text.body.copyWith(
                color: $styles.colors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: $styles.insets.xs),
            FilledButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                onRetry();
              },
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

class const _CreatorProfileHeader({
  required final CreatorProfile profile,
  required final ColorScheme colorScheme,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    final description = profile.description?.trim();
    final stats = <String>[
      if (profile.subscribers case final subscribers?)
        l10n.subscribersCount(_formatCount(subscribers, l10n)),
      if (profile.videos case final videos?)
        l10n.videosCount(_formatCount(videos, l10n)),
      if (profile.isLive == true) l10n.liveNow,
    ];

    return Padding(
      padding: EdgeInsets.all($styles.insets.sm),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.all($styles.insets.sm),
          child: Semantics(
            container: true,
            label: [
              profile.name,
              l10n.creatorLabel('@${profile.id}'),
              if (description != null && description.isNotEmpty) description,
              ...stats,
            ].join(l10n.commaSeparator),
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CreatorAvatar(profile: profile, colorScheme: colorScheme),
                    SizedBox(width: $styles.insets.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: $styles.text.h3.copyWith(
                              color: $styles.colors.onSurfaceStrong,
                            ),
                          ),
                          SizedBox(height: $styles.insets.xxs),
                          Text(
                            l10n.creatorLabel('@${profile.id}'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: $styles.text.bodySmall.copyWith(
                              color: $styles.colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: $styles.insets.sm),
                Text(
                  description != null && description.isNotEmpty
                      ? description
                      : l10n.spaceDescriptionUnavailable,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: $styles.text.bodySmall.copyWith(
                    color: $styles.colors.onSurface,
                    height: 1.4,
                  ),
                ),
                if (stats.isNotEmpty) ...[
                  SizedBox(height: $styles.insets.sm),
                  Wrap(
                    spacing: $styles.insets.sm,
                    runSpacing: $styles.insets.xxs,
                    children: [
                      for (final stat in stats)
                        Text(
                          stat,
                          style: $styles.text.bodySmallBold.copyWith(
                            color: $styles.colors.accentText,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class const _CreatorAvatar({
  required final CreatorProfile profile,
  required final ColorScheme colorScheme,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = profile.thumbnailUrl;
    final hasThumbnail = thumbnailUrl != null && thumbnailUrl.isNotEmpty;
    final initial = profile.name.isNotEmpty
        ? profile.name[0].toUpperCase()
        : '?';

    return Tooltip(
      message: profile.name,
      child: CircleAvatar(
        radius: 40,
        backgroundColor: colorScheme.primaryContainer,
        backgroundImage: hasThumbnail
            ? ResizeImage.resizeIfNeeded(
                160,
                160,
                CachedNetworkImageProvider(thumbnailUrl),
              )
            : null,
        child: hasThumbnail
            ? null
            : Text(
                initial,
                style: $styles.text.h3.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
      ),
    );
  }
}

String _formatCount(int count, AppLocalizations l10n) {
  if (count >= 100000000) {
    return l10n.countCompactYi((count / 100000000).toStringAsFixed(1));
  }
  if (count >= 10000) {
    return l10n.countCompactWan((count / 10000).toStringAsFixed(1));
  }
  return '$count';
}
