import 'dart:async';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:data/data.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';

import '../../data/repository/channel_playlists_repository.dart';
import '../../data/repository/channel_videos_repository.dart';
import '../../data/repository/creator_profile_repository.dart';
import '../../data/repository/local_library_repository.dart';
import '../../datastore/preferences_data_source.dart';
import '../../design/design.dart';
import '../../l10n/localization_file/app_localizations.dart';
import '../../main.dart';
import '../../routing/navigation_callbacks.dart';
import '../../ui/common/rate_limit_retry.dart';
import '../../ui/creator_subscribe_button.dart';
import '../../ui/video_card.dart';
import '../setting/app_settings.dart';
import 'bloc/channel_playlists_cubit.dart';
import 'bloc/channel_videos_cubit.dart';

typedef _SubscribeToggle = Future<void> Function(CreatorProfile profile);

/// 一个已挂载的频道 tab：标签文案与内容视图。
typedef _ChannelTab = ({String label, Widget view});

class const SpaceScreen({
  super.key,
  final VoidCallback? onBackClick,
  final VideoNavCallback? onVideo,
  final PlaylistNavCallback? onPlaylist,
  required final String mid,
}) extends StatefulWidget {
  @override
  State<SpaceScreen> createState() => _SpaceScreenState();
}

class _SpaceScreenState() extends State<SpaceScreen> {
  CreatorProfileRepository? _repository;
  Future<Result<CreatorProfile, Exception>>? _profileFuture;
  ChannelTabSettings _tabSettings = const ChannelTabSettings();
  bool _tabSettingsReady = false;
  bool _tabSettingsRequested = false;
  LocalLibraryRepository? _localLibrary;
  String? _sourceId;
  bool _isSubscribed = false;
  bool _subscriptionReady = false;
  bool _subscriptionRequested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = context.read<CreatorProfileRepository?>();
    if (_profileFuture == null || !identical(repository, _repository)) {
      _repository = repository;
      _profileFuture = _loadProfile();
    }

    _localLibrary ??= context.read<LocalLibraryRepository?>();
    _sourceId ??= context.read<MediaSource?>()?.id;

    if (!_tabSettingsRequested) {
      _tabSettingsRequested = true;
      _loadTabSettings();
    }

    if (!_subscriptionRequested) {
      _subscriptionRequested = true;
      unawaited(_loadSubscription());
    }
  }

  Future<void> _loadSubscription() async {
    final repository = _localLibrary;
    final sourceId = _sourceId;
    if (repository == null || sourceId == null) return;

    final requestedMid = widget.mid;
    try {
      final subscribed = await repository.isSubscribed(sourceId, requestedMid);
      if (!mounted || widget.mid != requestedMid) return;
      setState(() {
        _isSubscribed = subscribed;
        _subscriptionReady = true;
      });
    } on Exception {
      if (!mounted || widget.mid != requestedMid) return;
      setState(() => _subscriptionReady = false);
    }
  }

  Future<void> _toggleSubscription(CreatorProfile profile) async {
    final repository = _localLibrary;
    final sourceId = _sourceId;
    if (repository == null || sourceId == null) return;

    final requestedMid = widget.mid;
    final target = !_isSubscribed;
    setState(() => _isSubscribed = target);

    try {
      await repository.setSubscription(
        sourceId: sourceId,
        creator: profile,
        subscribed: target,
      );
    } on Exception catch (error) {
      if (!mounted) return;
      if (widget.mid == requestedMid) {
        setState(() => _isSubscribed = !target);
      }
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.operationFailed('$error'))));
    }
  }

  Future<void> _loadTabSettings() async {
    final preferences = context.read<PreferencesDataSource?>();
    if (preferences == null) {
      if (mounted) setState(() => _tabSettingsReady = true);
      return;
    }

    final settings = await ChannelTabSettings.load(preferences);
    if (!mounted) return;
    setState(() {
      _tabSettings = settings;
      _tabSettingsReady = true;
    });
  }

  @override
  void didUpdateWidget(covariant SpaceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mid == widget.mid) return;
    _profileFuture = _loadProfile();
    _isSubscribed = false;
    _subscriptionReady = false;
    unawaited(_loadSubscription());
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
    final l10n = AppLocalizations.of(context)!;
    final toggleSubscription = _localLibrary != null && _sourceId != null
        ? _toggleSubscription
        : null;

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
      body: !_tabSettingsReady
          ? Center(
              child: CircularProgressIndicator(
                color: $styles.colors.accentFill,
              ),
            )
          : FutureBuilder<Result<CreatorProfile, Exception>>(
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
                  return _ProfileLoadError(
                    onRetry: _retry,
                    error: snapshot.error,
                  );
                }

                return switch (snapshot.data!) {
                  Success(:final success) => _SpaceContent(
                    profile: success,
                    mid: widget.mid,
                    colorScheme: colorScheme,
                    onVideo: widget.onVideo,
                    onPlaylist: widget.onPlaylist,
                    tabSettings: _tabSettings,
                    isSubscribed: _subscriptionReady ? _isSubscribed : null,
                    onToggleSubscribe: toggleSubscription,
                  ),
                  Error(:final error) => _ProfileLoadError(
                    onRetry: _retry,
                    error: error,
                  ),
                };
              },
            ),
    );
  }
}

/// 资料头 + 内容 tab。
///
/// tab 按数据源真实能力生成：视频 tab 在有 `ChannelVideosRepository` 时挂载
/// 网格（无能力时保留一个说明页）；合集 tab 只在数据源提供
/// `ChannelPlaylistsRepository` 时出现。直播 / 短视频没有可用的频道列表接口，
/// 因此不挂空 tab。用户关闭某个 tab 后该 tab 及其内容都不挂载，因此也不会
/// 发起对应网络请求。
class const _SpaceContent({
  required final CreatorProfile profile,
  required final String mid,
  required final ColorScheme colorScheme,
  required final VideoNavCallback? onVideo,
  required final PlaylistNavCallback? onPlaylist,
  required final ChannelTabSettings tabSettings,
  required final bool? isSubscribed,
  required final _SubscribeToggle? onToggleSubscribe,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final videosRepository = context.read<ChannelVideosRepository?>();
    final playlistsRepository = context.read<ChannelPlaylistsRepository?>();

    final tabs = <_ChannelTab>[
      if (tabSettings.isVisible(ChannelTabs.videos))
        (
          label: l10n.videoTab,
          view: videosRepository == null
              ? const _ChannelVideosUnsupported()
              : BlocProvider<ChannelVideosCubit>(
                  key: ValueKey('$mid-videos'),
                  create: (_) => ChannelVideosCubit(videosRepository, mid),
                  child: _ChannelVideosGrid(onVideo: onVideo, mid: mid),
                ),
        ),
      if (tabSettings.isVisible(ChannelTabs.playlists) &&
          playlistsRepository != null)
        (
          label: l10n.channelTabPlaylists,
          view: BlocProvider<ChannelPlaylistsCubit>(
            key: ValueKey('$mid-playlists'),
            create: (_) => ChannelPlaylistsCubit(playlistsRepository, mid),
            child: _ChannelPlaylistsList(onPlaylist: onPlaylist, mid: mid),
          ),
        ),
    ];

    final header = _CreatorProfileHeader(
      profile: profile,
      colorScheme: colorScheme,
      isSubscribed: isSubscribed,
      onToggleSubscribe: onToggleSubscribe,
    );

    if (tabs.isEmpty) {
      return ListView(children: [header]);
    }

    final tabBar = TabBar(
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      onTap: (_) => HapticFeedback.selectionClick(),
      tabs: [for (final tab in tabs) Tab(text: tab.label)],
    );
    final tabBarHeight = _tabBarHeight(context);

    return DefaultTabController(
      length: tabs.length,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(child: header),
          SliverPersistentHeader(
            pinned: true,
            delegate: _ChannelTabBar(tabBar: tabBar, height: tabBarHeight),
          ),
        ],
        body: TabBarView(children: [for (final tab in tabs) tab.view]),
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
class const _ChannelVideosGrid({
  required final VideoNavCallback? onVideo,
  required final String mid,
}) extends StatelessWidget {
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
              firstPageErrorIndicatorBuilder: (context, error) =>
                  _ChannelSectionError(
                    error: error,
                    // scope 按 mid 分开：换一个 UP 主就是另一份额度，不能沿用
                    // 上一个 UP 主的连击次数。
                    scope: 'space.videos.$mid',
                    onRetry: () =>
                        context.read<ChannelVideosCubit>().fetchNextPage(),
                  ),
              newPageErrorIndicatorBuilder: (context, error) =>
                  _ChannelSectionPageError(
                    error: error,
                    scope: 'space.videos.$mid.next',
                    onRetry: () =>
                        context.read<ChannelVideosCubit>().fetchNextPage(),
                  ),
              noItemsFoundIndicatorBuilder: (context) =>
                  const _ChannelVideosEmpty(),
            ),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              mainAxisSpacing: $styles.insets.sm,
              crossAxisSpacing: $styles.insets.sm,
              // 高度按卡片文字块的预算算，比例写死会随字号变化把标题挤掉。
              mainAxisExtent: videoCardExtent(context, 200),
            ),
          ),
        ],
      ),
    );
  }
}

class const _ChannelSectionError({
  required final Object? error,
  required final VoidCallback onRetry,
  required final String scope,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rateLimited = isRateLimited(error);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.error, color: $styles.colors.outline),
          SizedBox(height: $styles.insets.xs),
          Text(
            rateLimited
                ? l10n.rateLimitedRetryLater
                : l10n.loadFailedRetryLater,
            textAlign: TextAlign.center,
            style: $styles.text.body.copyWith(
              color: $styles.colors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: $styles.insets.xs),
          RetryCooldownButton(
            rateLimited: rateLimited,
            scope: scope,
            failure: error,
            onRetry: onRetry,
          ),
        ],
      ),
    );
  }
}

class const _ChannelSectionPageError({
  required final Object? error,
  required final VoidCallback onRetry,
  required final String scope,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rateLimited = isRateLimited(error);
    return Padding(
      padding: EdgeInsets.all($styles.insets.sm),
      child: Center(
        // 限流时也保留入口，只是先走冷却倒计时：分页失败后用户仍然要能接着
        // 往下翻，只是不能立刻重发同一个被拒的请求。
        child: RetryCooldownInlineButton(
          rateLimited: rateLimited,
          scope: scope,
          failure: error,
          onRetry: onRetry,
          label: rateLimited
              ? l10n.rateLimitedRetryLater
              : l10n.moreLoadFailedRetry,
        ),
      ),
    );
  }
}

class const _ChannelVideosEmpty() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
    final l10n = AppLocalizations.of(context)!;
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

class const _ChannelPlaylistsList({
  required final PlaylistNavCallback? onPlaylist,
  required final String mid,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChannelPlaylistsCubit, PagingState<int, PlaylistDetail>>(
      builder: (context, state) => PagedListView<int, PlaylistDetail>(
        state: state,
        fetchNextPage: () =>
            context.read<ChannelPlaylistsCubit>().fetchNextPage(),
        builderDelegate: PagedChildBuilderDelegate<PlaylistDetail>(
          itemBuilder: (context, playlist, index) => _ChannelPlaylistTile(
            key: ValueKey(playlist.id),
            playlist: playlist,
            onTap: onPlaylist == null
                ? null
                : () => onPlaylist?.call(playlist.id),
          ),
          firstPageProgressIndicatorBuilder: (context) => Center(
            child: CircularProgressIndicator(color: $styles.colors.accentFill),
          ),
          firstPageErrorIndicatorBuilder: (context, error) =>
              _ChannelSectionError(
                error: error,
                scope: 'space.playlists.$mid',
                onRetry: () =>
                    context.read<ChannelPlaylistsCubit>().fetchNextPage(),
              ),
          newPageErrorIndicatorBuilder: (context, error) =>
              _ChannelSectionPageError(
                error: error,
                scope: 'space.playlists.$mid.next',
                onRetry: () =>
                    context.read<ChannelPlaylistsCubit>().fetchNextPage(),
              ),
          noItemsFoundIndicatorBuilder: (context) =>
              const _ChannelPlaylistsEmpty(),
        ),
      ),
    );
  }
}

class const _ChannelPlaylistTile({
  super.key,
  required final PlaylistDetail playlist,
  required final VoidCallback? onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final total = playlist.totalCount;

    return ListTile(
      onTap: onTap,
      leading: _cover(colorScheme),
      title: Text(
        playlist.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: $styles.text.body.copyWith(color: colorScheme.onSurface),
      ),
      subtitle: total == null
          ? null
          : Text(
              l10n.playlistItemCount('$total'),
              style: $styles.text.bodySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
    );
  }

  Widget _cover(ColorScheme colorScheme) {
    final url = playlist.coverUrl;
    final fallback = SizedBox(
      width: 96,
      height: 56,
      child: Icon(AppIcons.videoLibrary, color: colorScheme.onSurfaceVariant),
    );
    if (url == null || url.isEmpty) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular($styles.corners.sm),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 96,
        height: 56,
        memCacheWidth: 320,
        fit: BoxFit.cover,
        errorBuilder: (context, url, error) => fallback,
      ),
    );
  }
}

class const _ChannelPlaylistsEmpty() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.videoLibrary, color: $styles.colors.outline),
          SizedBox(height: $styles.insets.xs),
          Text(
            l10n.channelPlaylistsEmpty,
            style: $styles.text.body.copyWith(
              color: $styles.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class const _ProfileLoadError({
  required final VoidCallback onRetry,
  required final Object? error,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rateLimited = isRateLimited(error);
    return Center(
      child: Padding(
        padding: EdgeInsets.all($styles.insets.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.error, color: $styles.colors.outline),
            SizedBox(height: $styles.insets.xs),
            Text(
              rateLimited
                  ? l10n.rateLimitedRetryLater
                  : l10n.loadFailedRetryLater,
              textAlign: TextAlign.center,
              style: $styles.text.body.copyWith(
                color: $styles.colors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: $styles.insets.xs),
            RetryCooldownButton(
              rateLimited: rateLimited,
              scope: 'space.profile',
              failure: error,
              onRetry: onRetry,
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
  required final bool? isSubscribed,
  required final _SubscribeToggle? onToggleSubscribe,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final description = profile.description?.trim();
    final stats = <String>[
      if (profile.subscribers case final subscribers?)
        l10n.subscribersCount(_formatCount(subscribers, l10n)),
      if (profile.videos case final videos?)
        l10n.videosCount(_formatCount(videos, l10n)),
      if (profile.isLive == true) l10n.liveNow,
    ];
    final subscribed = isSubscribed;
    final toggleSubscribe = onToggleSubscribe;

    return Padding(
      padding: EdgeInsets.all($styles.insets.sm),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.all($styles.insets.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                container: true,
                label: [
                  profile.name,
                  l10n.creatorLabel('@${profile.id}'),
                  if (description != null && description.isNotEmpty)
                    description,
                  ...stats,
                ].join(l10n.commaSeparator),
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CreatorAvatar(
                          profile: profile,
                          colorScheme: colorScheme,
                        ),
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
              if (subscribed != null && toggleSubscribe != null) ...[
                SizedBox(height: $styles.insets.sm),
                CreatorSubscribeButton(
                  isSubscribed: subscribed,
                  onPressed: () => unawaited(toggleSubscribe(profile)),
                ),
              ],
            ],
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
