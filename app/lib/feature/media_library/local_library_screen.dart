import 'package:data/data.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/repository/local_library_repository.dart';
import '../../database/app_database.dart';
import '../../l10n/localization_file/app_localizations.dart';
import '../../l10n/localization_file/app_localizations_zh.dart';
import '../../main.dart';
import '../../providers/media_sources_provider.dart';

/// The local-only library shell.
///
/// [history] is supplied by the existing history screen so its pagination and
/// source-aware navigation remain owned by the parent route. The other three
/// tabs read and write the source-scoped local-library repository directly.
class const LocalLibraryScreen({
  super.key,
  required final Widget history,
  required final void Function(String sourceId, String videoId) onVideoTap,
  required final void Function(String sourceId, String creatorId) onCreatorTap,
}) extends StatefulWidget {
  @override
  State<LocalLibraryScreen> createState() => _LocalLibraryScreenState();
}

class _LocalLibraryScreenState() extends State<LocalLibraryScreen> {
  late final LocalLibraryRepository _repository;
  late Stream<List<LocalBookmarkEntity>> _bookmarks;
  late Stream<List<LocalSubscriptionEntity>> _subscriptions;
  late Stream<List<LocalPlaylistEntity>> _playlists;

  int _tabIndex = 0;
  int _retry = 0;
  String? _sourceId;
  String? _operationError;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _repository = context.read<LocalLibraryRepository>();
    _loadStreams();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    final catalog = context.read<MediaSourceCatalog>();
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.localLibrary)),
        body: Column(
          children: [
            if (_tabIndex != 0) _scopeBar(catalog),
            if (_operationError case final error?) _OperationError(error),
            if (_busy) const LinearProgressIndicator(),
            TabBar(
              onTap: (index) {
                HapticFeedback.selectionClick();
                setState(() => _tabIndex = index);
              },
              tabs: [
                Tab(text: l10n.history),
                Tab(text: l10n.favorite),
                Tab(text: l10n.playlists),
                Tab(text: l10n.subscribe),
              ],
            ),
            Expanded(
              child: IndexedStack(
                index: _tabIndex,
                children: [
                  widget.history,
                  _BookmarksTab(
                    key: ValueKey('bookmarks-$_retry'),
                    stream: _bookmarks,
                    sourceId: _sourceId,
                    sourceName: _sourceName,
                    onVideoTap: widget.onVideoTap,
                    onCreatorTap: widget.onCreatorTap,
                    onRetry: _retryStreams,
                    busy: _busy,
                    onRemove: (bookmark) => _runOperation(
                      () => _repository.setBookmark(
                        sourceId: bookmark.sourceId,
                        video: _videoFromBookmark(bookmark),
                        bookmarked: false,
                      ),
                    ),
                  ),
                  _PlaylistsTab(
                    key: ValueKey('playlists-$_retry'),
                    repository: _repository,
                    stream: _playlists,
                    sourceId: _sourceId,
                    sourceName: _sourceName,
                    onVideoTap: widget.onVideoTap,
                    onRetry: _retryStreams,
                    busy: _busy,
                    onCreate: _createPlaylist,
                    onDelete: (playlist) =>
                        _deletePlaylist(playlist.internalId),
                    onRename: _renamePlaylist,
                    onAddBookmarks: _addBookmarks,
                    onRemoveItem: (item) => _runOperation(
                      () => _repository.removePlaylistItem(item.internalId),
                    ),
                    onMoveItem: _movePlaylistItem,
                  ),
                  _SubscriptionsTab(
                    key: ValueKey('subscriptions-$_retry'),
                    stream: _subscriptions,
                    sourceId: _sourceId,
                    sourceName: _sourceName,
                    onCreatorTap: widget.onCreatorTap,
                    onRetry: _retryStreams,
                    busy: _busy,
                    onUnsubscribe: (subscription) => _runOperation(
                      () => _repository.setSubscription(
                        sourceId: subscription.sourceId,
                        creator: CreatorProfile(
                          id: subscription.originalId,
                          name: subscription.name,
                          thumbnailUrl: subscription.thumbnailUrl,
                        ),
                        subscribed: false,
                      ),
                    ),
                    onSetGroup: _setSubscriptionGroup,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scopeBar(MediaSourceCatalog catalog) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    final sourceName = _sourceName(_sourceId);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        $styles.insets.sm,
        $styles.insets.xs,
        $styles.insets.sm,
        0,
      ),
      child: Row(
        children: [
          Icon(Icons.filter_list, color: $styles.colors.onSurfaceVariant),
          SizedBox(width: $styles.insets.xs),
          Expanded(
            child: Text(
              sourceName == null
                  ? l10n.allSources
                  : l10n.sourceLabel(sourceName),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: $styles.text.bodySmall.copyWith(
                color: $styles.colors.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: catalog.definitions.isEmpty ? null : _chooseSource,
            child: Text(l10n.filter),
          ),
        ],
      ),
    );
  }

  String? _sourceName(String? sourceId) {
    if (sourceId == null) return null;
    final definition = context.read<MediaSourceCatalog>().find(sourceId);
    return definition?.name ?? sourceId;
  }

  Future<void> _chooseSource() async {
    final catalog = context.read<MediaSourceCatalog>();
    final selected = await showDialog<({String? sourceId})>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
        return AlertDialog(
          title: Text(l10n.selectSource),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SimpleDialogOption(
                    onPressed: () =>
                        Navigator.of(context).pop((sourceId: null)),
                    child: Text(l10n.allSources),
                  ),
                  for (final definition in catalog.definitions)
                    SimpleDialogOption(
                      onPressed: () =>
                          Navigator.of(context).pop((sourceId: definition.id)),
                      child: Text(definition.name),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (!mounted || selected == null) return;
    setState(() {
      _sourceId = selected.sourceId;
    });
  }

  Future<void> _createPlaylist() => _runOperation(() async {
    final request = await _showCreatePlaylistDialog(
      context,
      initialSourceId: _sourceId,
    );
    if (!mounted || request == null) return;
    await _repository.createPlaylist(request.sourceId, request.name);
  });

  Future<void> _renamePlaylist(LocalPlaylistEntity playlist) =>
      _runOperation(() async {
        final newName = await _showRenamePlaylistDialog(
          context,
          initialName: playlist.name,
        );
        if (!mounted || newName == null) return;
        await _repository.renamePlaylist(playlist.internalId, newName);
      });

  Future<void> _deletePlaylist(int playlistId) => _runOperation(() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
        return AlertDialog(
          title: Text(l10n.deletePlaylistConfirm),
          content: Text(l10n.deletePlaylistNote),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );
    if (mounted && confirmed == true) {
      await _repository.deletePlaylist(playlistId);
    }
  });

  Future<void> _addBookmarks(LocalPlaylistEntity playlist) =>
      _runOperation(() async {
        final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
        final bookmarks = (await _repository.getBookmarks())
            .where((bookmark) => bookmark.sourceId == playlist.sourceId)
            .toList(growable: false);
        if (!mounted) return;
        if (bookmarks.isEmpty) {
          _reportError(l10n.noFavoritesFromSource);
          return;
        }
        final selected = await showDialog<List<LocalBookmarkEntity>>(
          context: context,
          builder: (_) => _BookmarkSelectionDialog(bookmarks: bookmarks),
        );
        if (!mounted || selected == null || selected.isEmpty) return;
        await _repository.addVideosToPlaylist(
          playlistId: playlist.internalId,
          sourceId: playlist.sourceId,
          videos: selected.map(_videoFromBookmark).toList(growable: false),
        );
      });

  Future<void> _setSubscriptionGroup(LocalSubscriptionEntity subscription) =>
      _runOperation(() async {
        final groupName = await _showGroupDialog(
          context,
          initialValue: subscription.groupName,
        );
        if (!mounted || groupName == null) return;
        await _repository.setSubscriptionGroup(
          subscription.sourceId,
          subscription.originalId,
          groupName,
        );
      });

  Future<void> _movePlaylistItem(
    LocalPlaylistItemEntity item,
    int fromIndex,
    int toIndex,
  ) => _runOperation(
    () => _repository.movePlaylistItem(
      playlistId: item.playlistId,
      fromIndex: fromIndex,
      toIndex: toIndex,
    ),
  );

  Future<void> _runOperation(Future<void> Function() operation) async {
    if (!mounted || _busy) return;
    setState(() {
      _busy = true;
      _operationError = null;
    });
    try {
      await operation();
    } on Object catch (error) {
      if (mounted) {
        final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
        _reportError(l10n.operationFailed(error.toString()));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _reportError(String error) {
    if (!mounted) return;
    setState(() => _operationError = error);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error)));
  }

  void _retryStreams() {
    if (!mounted) return;
    setState(() {
      _retry++;
      _loadStreams();
    });
  }

  void _loadStreams() {
    _bookmarks = _repository.watchBookmarks();
    _subscriptions = _repository.watchSubscriptions();
    _playlists = _repository.watchPlaylists();
  }
}

typedef _PlaylistRequest = ({String sourceId, String name});

class const _BookmarksTab({
  super.key,
  required final Stream<List<LocalBookmarkEntity>> stream,
  required final String? sourceId,
  required final String? Function(String?) sourceName,
  required final void Function(String sourceId, String videoId) onVideoTap,
  required final void Function(String sourceId, String creatorId) onCreatorTap,
  required final VoidCallback onRetry,
  required final bool busy,
  required final Future<void> Function(LocalBookmarkEntity bookmark) onRemove,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    return StreamBuilder<List<LocalBookmarkEntity>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return _LibraryMessage(
            icon: Icons.bookmark_outline,
            message: l10n.loadingFavorites,
            loading: true,
          );
        }
        if (snapshot.hasError) {
          return _LibraryMessage(
            icon: Icons.error_outline,
            message: l10n.favoritesLoadFailed,
            actionLabel: l10n.retry,
            onAction: onRetry,
          );
        }
        final bookmarks = (snapshot.data ?? const <LocalBookmarkEntity>[])
            .where(
              (bookmark) => sourceId == null || bookmark.sourceId == sourceId,
            )
            .toList(growable: false);
        if (bookmarks.isEmpty) {
          return _LibraryMessage(
            icon: Icons.bookmark_border,
            message: l10n.noFavoritesYet,
          );
        }
        return ListView.separated(
          padding: EdgeInsets.symmetric(vertical: $styles.insets.xs),
          itemCount: bookmarks.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final bookmark = bookmarks[index];
            final creatorId = bookmark.creatorProfileId;
            return ListTile(
              leading: const _LibraryLeading(icon: Icons.bookmark_outline),
              title: Text(
                bookmark.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                [
                  ?sourceName(bookmark.sourceId),
                  if (bookmark.creatorProfileName case final name?
                      when name.isNotEmpty)
                    name,
                ].join(l10n.spacedDot),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                HapticFeedback.lightImpact();
                onVideoTap(bookmark.sourceId, bookmark.originalId);
              },
              trailing: PopupMenuButton<_BookmarkAction>(
                enabled: !busy,
                tooltip: l10n.favoriteActions,
                onSelected: (action) {
                  switch (action) {
                    case _BookmarkAction.remove:
                      onRemove(bookmark);
                    case _BookmarkAction.creator:
                      if (creatorId != null && creatorId.isNotEmpty) {
                        onCreatorTap(bookmark.sourceId, creatorId);
                      }
                  }
                },
                itemBuilder: (context) => [
                  if (creatorId != null && creatorId.isNotEmpty)
                    PopupMenuItem(
                      value: _BookmarkAction.creator,
                      child: Text(l10n.openCreator),
                    ),
                  PopupMenuItem(
                    value: _BookmarkAction.remove,
                    child: Text(l10n.unfavorite),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

enum _BookmarkAction() {
  remove,
  creator,
}

class const _PlaylistsTab({
  super.key,
  required final LocalLibraryRepository repository,
  required final Stream<List<LocalPlaylistEntity>> stream,
  required final String? sourceId,
  required final String? Function(String?) sourceName,
  required final void Function(String sourceId, String videoId) onVideoTap,
  required final VoidCallback onRetry,
  required final bool busy,
  required final Future<void> Function() onCreate,
  required final Future<void> Function(LocalPlaylistEntity playlist) onDelete,
  required final Future<void> Function(LocalPlaylistEntity playlist) onRename,
  required final Future<void> Function(LocalPlaylistEntity playlist)
  onAddBookmarks,
  required final Future<void> Function(LocalPlaylistItemEntity item)
  onRemoveItem,
  required final Future<void> Function(
    LocalPlaylistItemEntity item,
    int fromIndex,
    int toIndex,
  )
  onMoveItem,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    return StreamBuilder<List<LocalPlaylistEntity>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return _LibraryMessage(
            icon: Icons.queue_music_outlined,
            message: l10n.loadingPlaylists,
            loading: true,
          );
        }
        if (snapshot.hasError) {
          return _LibraryMessage(
            icon: Icons.error_outline,
            message: l10n.playlistLoadFailed,
            actionLabel: l10n.retry,
            onAction: onRetry,
          );
        }
        final playlists = (snapshot.data ?? const <LocalPlaylistEntity>[])
            .where(
              (playlist) => sourceId == null || playlist.sourceId == sourceId,
            )
            .toList(growable: false);
        if (playlists.isEmpty) {
          return _LibraryMessage(
            icon: Icons.queue_music_outlined,
            message: l10n.noPlaylistsYet,
            actionLabel: l10n.newPlaylist,
            onAction: onCreate,
          );
        }
        return ListView(
          padding: EdgeInsets.only(bottom: $styles.insets.md),
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                $styles.insets.sm,
                $styles.insets.xs,
                $styles.insets.sm,
                0,
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: busy ? null : onCreate,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.newPlaylist),
                ),
              ),
            ),
            for (final playlist in playlists)
              _PlaylistCard(
                key: ValueKey(playlist.internalId),
                repository: repository,
                playlist: playlist,
                sourceName: sourceName(playlist.sourceId),
                sourceId: playlist.sourceId,
                onVideoTap: onVideoTap,
                onRetry: onRetry,
                busy: busy,
                onDelete: () => onDelete(playlist),
                onRename: () => onRename(playlist),
                onAddBookmarks: () => onAddBookmarks(playlist),
                onRemoveItem: onRemoveItem,
                onMoveItem: onMoveItem,
              ),
          ],
        );
      },
    );
  }
}

class const _PlaylistCard({
  super.key,
  required final LocalLibraryRepository repository,
  required final LocalPlaylistEntity playlist,
  required final String? sourceName,
  required final String sourceId,
  required final void Function(String sourceId, String videoId) onVideoTap,
  required final VoidCallback onRetry,
  required final bool busy,
  required final VoidCallback onDelete,
  required final VoidCallback onAddBookmarks,
  required final VoidCallback onRename,
  required final Future<void> Function(LocalPlaylistItemEntity item)
  onRemoveItem,
  required final Future<void> Function(
    LocalPlaylistItemEntity item,
    int fromIndex,
    int toIndex,
  )
  onMoveItem,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    return Card(
      margin: EdgeInsets.fromLTRB(
        $styles.insets.sm,
        $styles.insets.xs,
        $styles.insets.sm,
        0,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              $styles.insets.sm,
              $styles.insets.xs,
              $styles.insets.xxs,
              $styles.insets.xxs,
            ),
            child: Row(
              children: [
                Icon(Icons.queue_music, color: $styles.colors.accentText),
                SizedBox(width: $styles.insets.xs),
                Expanded(
                  child: Text(
                    playlist.name,
                    style: $styles.text.bodyBold.copyWith(
                      color: $styles.colors.onSurfaceStrong,
                    ),
                  ),
                ),
                PopupMenuButton<_PlaylistAction>(
                  tooltip: l10n.playlistActions,
                  onSelected: (action) {
                    switch (action) {
                      case _PlaylistAction.addBookmarks:
                        if (!busy) onAddBookmarks();
                      case _PlaylistAction.delete:
                        if (!busy) onDelete();
                      case _PlaylistAction.rename:
                        if (!busy) onRename();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _PlaylistAction.addBookmarks,
                      enabled: !busy,
                      child: Text(l10n.addFavorite),
                    ),
                    PopupMenuItem(
                      value: _PlaylistAction.rename,
                      enabled: !busy,
                      child: Text(l10n.renamePlaylist),
                    ),
                    PopupMenuItem(
                      value: _PlaylistAction.delete,
                      enabled: !busy,
                      child: Text(l10n.deletePlaylist),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: $styles.insets.sm),
            child: Text(
              sourceName == null
                  ? playlist.sourceId
                  : l10n.sourceLabel(sourceName!),
              style: $styles.text.bodySmall.copyWith(
                color: $styles.colors.onSurfaceVariant,
              ),
            ),
          ),
          _PlaylistItemsView(
            key: ValueKey('items-${playlist.internalId}'),
            repository: repository,
            playlistId: playlist.internalId,
            sourceId: sourceId,
            onVideoTap: onVideoTap,
            onRetry: onRetry,
            busy: busy,
            onRemoveItem: onRemoveItem,
            onMoveItem: onMoveItem,
          ),
        ],
      ),
    );
  }
}

enum _PlaylistAction() {
  addBookmarks,
  delete,
  rename,
}

class const _PlaylistItemsView({
  super.key,
  required final LocalLibraryRepository repository,
  required final int playlistId,
  required final String sourceId,
  required final void Function(String sourceId, String videoId) onVideoTap,
  required final VoidCallback onRetry,
  required final bool busy,
  required final Future<void> Function(LocalPlaylistItemEntity item)
  onRemoveItem,
  required final Future<void> Function(
    LocalPlaylistItemEntity item,
    int fromIndex,
    int toIndex,
  )
  onMoveItem,
}) extends StatefulWidget {
  @override
  State<_PlaylistItemsView> createState() => _PlaylistItemsViewState();
}

class _PlaylistItemsViewState() extends State<_PlaylistItemsView> {
  late final Stream<List<LocalPlaylistItemEntity>> _items;
  final TextEditingController _searchController = TextEditingController();
  bool _isEditing = false;
  final Set<int> _selectedItems = <int>{};

  @override
  void initState() {
    super.initState();
    _items = widget.repository.watchPlaylistItems(widget.playlistId);
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleItem(int itemId) {
    setState(() {
      if (_selectedItems.contains(itemId)) {
        _selectedItems.remove(itemId);
      } else {
        _selectedItems.add(itemId);
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedItems.isEmpty) return;
    final count = _selectedItems.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
        return AlertDialog(
          title: Text(l10n.batchDeleteConfirm),
          content: Text(l10n.batchDeleteNote(count)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );
    if (mounted && confirmed == true) {
      await widget.repository.deletePlaylistItems(
        playlistId: widget.playlistId,
        itemIds: _selectedItems.toList(),
      );
      setState(() {
        _selectedItems.clear();
        _isEditing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            $styles.insets.sm,
            $styles.insets.xs,
            $styles.insets.sm,
            $styles.insets.xs,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.itemsSearchHint,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(width: $styles.insets.xs),
              if (_isEditing) ...[
                TextButton(
                  onPressed: () => setState(() {
                    _isEditing = false;
                    _selectedItems.clear();
                  }),
                  child: Text(l10n.done),
                ),
                if (_selectedItems.isNotEmpty)
                  FilledButton(
                    onPressed: _deleteSelected,
                    child: Text(l10n.deleteSelected),
                  ),
              ] else
                OutlinedButton(
                  onPressed: () => setState(() => _isEditing = true),
                  child: Text(l10n.editMode),
                ),
            ],
          ),
        ),
        StreamBuilder<List<LocalPlaylistItemEntity>>(
          stream: _items,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all($styles.insets.sm),
                      child: Text(
                        l10n.itemsLoadFailed,
                        style: $styles.text.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onRetry,
                    child: Text(l10n.retry),
                  ),
                ],
              );
            }
            final allItems = snapshot.data ?? const <LocalPlaylistItemEntity>[];
            final searchText = _searchController.text.trim().toLowerCase();
            final items = allItems
                .where((item) => item.sourceId == widget.sourceId)
                .where(
                  (item) =>
                      searchText.isEmpty ||
                      item.title.toLowerCase().contains(searchText),
                )
                .toList(growable: false);
            if (items.isEmpty) {
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  $styles.insets.sm,
                  0,
                  $styles.insets.sm,
                  $styles.insets.xs,
                ),
                child: Text(
                  l10n.listEmpty,
                  style: $styles.text.bodySmall.copyWith(
                    color: $styles.colors.onSurfaceVariant,
                  ),
                ),
              );
            }
            return Column(
              children: [
                for (var index = 0; index < items.length; index++)
                  _PlaylistItemRow(
                    key: ValueKey(items[index].internalId),
                    item: items[index],
                    isFirst: index == 0,
                    isLast: index == items.length - 1,
                    busy: widget.busy,
                    onTap: () => widget.onVideoTap(
                      items[index].sourceId,
                      items[index].originalId,
                    ),
                    onRemove: widget.busy
                        ? null
                        : () => widget.onRemoveItem(items[index]),
                    onMoveUp: index == 0
                        ? null
                        : () {
                            final actualIndex = allItems.indexWhere(
                              (item) =>
                                  item.internalId == items[index].internalId,
                            );
                            if (!widget.busy) {
                              widget.onMoveItem(
                                items[index],
                                actualIndex,
                                actualIndex - 1,
                              );
                            }
                          },
                    onMoveDown: index == items.length - 1
                        ? null
                        : () {
                            final actualIndex = allItems.indexWhere(
                              (item) =>
                                  item.internalId == items[index].internalId,
                            );
                            if (!widget.busy) {
                              widget.onMoveItem(
                                items[index],
                                actualIndex,
                                actualIndex + 1,
                              );
                            }
                          },
                    isSelected: _selectedItems.contains(
                      items[index].internalId,
                    ),
                    onToggleSelect: _isEditing
                        ? () => _toggleItem(items[index].internalId)
                        : null,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class const _PlaylistItemRow({
  super.key,
  required final LocalPlaylistItemEntity item,
  required final bool isFirst,
  required final bool isLast,
  required final bool busy,
  required final VoidCallback onTap,
  required final VoidCallback? onRemove,
  required final VoidCallback? onMoveUp,
  required final VoidCallback? onMoveDown,
  final bool isSelected = false,
  final VoidCallback? onToggleSelect,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    final isEditing = onToggleSelect != null;
    return ListTile(
      dense: true,
      leading: isEditing
          ? Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected
                  ? $styles.colors.accentText
                  : $styles.colors.onSurfaceVariant,
            )
          : const _LibraryLeading(icon: Icons.play_arrow_outlined),
      title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      onTap: () {
        HapticFeedback.lightImpact();
        if (isEditing) {
          onToggleSelect!();
        } else {
          onTap();
        }
      },
      trailing: isEditing
          ? null
          : PopupMenuButton<_PlaylistItemAction>(
              enabled: !busy,
              tooltip: l10n.itemActions,
              onSelected: (action) {
                switch (action) {
                  case _PlaylistItemAction.up:
                    onMoveUp?.call();
                  case _PlaylistItemAction.down:
                    onMoveDown?.call();
                  case _PlaylistItemAction.remove:
                    onRemove?.call();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _PlaylistItemAction.up,
                  enabled: !isFirst,
                  child: Text(l10n.moveUp),
                ),
                PopupMenuItem(
                  value: _PlaylistItemAction.down,
                  enabled: !isLast,
                  child: Text(l10n.moveDown),
                ),
                PopupMenuItem(
                  value: _PlaylistItemAction.remove,
                  child: Text(l10n.removeThisEntry),
                ),
              ],
            ),
    );
  }
}

enum _PlaylistItemAction() {
  up,
  down,
  remove,
}

class const _SubscriptionsTab({
  super.key,
  required final Stream<List<LocalSubscriptionEntity>> stream,
  required final String? sourceId,
  required final String? Function(String?) sourceName,
  required final void Function(String sourceId, String creatorId) onCreatorTap,
  required final VoidCallback onRetry,
  required final bool busy,
  required final Future<void> Function(LocalSubscriptionEntity subscription)
  onUnsubscribe,
  required final Future<void> Function(LocalSubscriptionEntity subscription)
  onSetGroup,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    return StreamBuilder<List<LocalSubscriptionEntity>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return _LibraryMessage(
            icon: Icons.person_add_alt_outlined,
            message: l10n.loadingSubscriptions,
            loading: true,
          );
        }
        if (snapshot.hasError) {
          return _LibraryMessage(
            icon: Icons.error_outline,
            message: l10n.subscriptionsLoadFailed,
            actionLabel: l10n.retry,
            onAction: onRetry,
          );
        }
        final subscriptions =
            (snapshot.data ?? const <LocalSubscriptionEntity>[])
                .where(
                  (subscription) =>
                      sourceId == null || subscription.sourceId == sourceId,
                )
                .toList(growable: false);
        if (subscriptions.isEmpty) {
          return _LibraryMessage(
            icon: Icons.person_add_alt_outlined,
            message: l10n.noSubscriptionsYet,
          );
        }

        final groups =
            <
              ({String groupName, String sourceId}),
              List<LocalSubscriptionEntity>
            >{};
        for (final subscription in subscriptions) {
          final group = subscription.groupName.trim();
          final key = (sourceId: subscription.sourceId, groupName: group);
          groups.putIfAbsent(key, () => []).add(subscription);
        }
        final sortedGroups = groups.keys.toList()
          ..sort((a, b) {
            final groupOrder = _groupCompare(a.groupName, b.groupName);
            return groupOrder == 0
                ? a.sourceId.compareTo(b.sourceId)
                : groupOrder;
          });
        return ListView(
          padding: EdgeInsets.only(bottom: $styles.insets.md),
          children: [
            for (final group in sortedGroups)
              _SubscriptionGroup(
                groupName: group.groupName.isEmpty
                    ? l10n.ungrouped
                    : group.groupName,
                sourceName: sourceName(group.sourceId),
                subscriptions: groups[group]!,
                onCreatorTap: onCreatorTap,
                onUnsubscribe: onUnsubscribe,
                onSetGroup: onSetGroup,
                busy: busy,
              ),
          ],
        );
      },
    );
  }

  static int _groupCompare(String a, String b) {
    if (a.isEmpty) return 1;
    if (b.isEmpty) return -1;
    return a.compareTo(b);
  }
}

class const _SubscriptionGroup({
  required final String groupName,
  required final String? sourceName,
  required final List<LocalSubscriptionEntity> subscriptions,
  required final void Function(String sourceId, String creatorId) onCreatorTap,
  required final Future<void> Function(LocalSubscriptionEntity subscription)
  onUnsubscribe,
  required final Future<void> Function(LocalSubscriptionEntity subscription)
  onSetGroup,
  required final bool busy,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    return Card(
      margin: EdgeInsets.fromLTRB(
        $styles.insets.sm,
        $styles.insets.xs,
        $styles.insets.sm,
        0,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            dense: true,
            title: Text(
              groupName,
              style: $styles.text.bodyBold.copyWith(
                color: $styles.colors.onSurfaceStrong,
              ),
            ),
            subtitle: sourceName == null
                ? null
                : Text(l10n.sourceLabel(sourceName!)),
          ),
          for (final subscription in subscriptions)
            ListTile(
              leading: const _LibraryLeading(icon: Icons.person_outline),
              title: Text(subscription.name),
              onTap: () {
                HapticFeedback.lightImpact();
                onCreatorTap(subscription.sourceId, subscription.originalId);
              },
              trailing: PopupMenuButton<_SubscriptionAction>(
                enabled: !busy,
                tooltip: l10n.subscriptionActions,
                onSelected: (action) {
                  switch (action) {
                    case _SubscriptionAction.group:
                      if (!busy) onSetGroup(subscription);
                    case _SubscriptionAction.remove:
                      if (!busy) onUnsubscribe(subscription);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: _SubscriptionAction.group,
                    child: Text(l10n.setGroup),
                  ),
                  PopupMenuItem(
                    value: _SubscriptionAction.remove,
                    child: Text(l10n.unsubscribe),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

enum _SubscriptionAction() {
  group,
  remove,
}

class const _LibraryLeading({required final IconData icon})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(icon, color: $styles.colors.onSurfaceVariant),
    );
  }
}

class const _LibraryMessage({
  required final IconData icon,
  required final String message,
  final String? actionLabel,
  final VoidCallback? onAction,
  final bool loading = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: $styles.colors.onSurfaceVariant),
          SizedBox(height: $styles.insets.sm),
          Text(
            message,
            style: $styles.text.body.copyWith(
              color: $styles.colors.onSurfaceVariant,
            ),
          ),
          if (loading) ...[
            SizedBox(height: $styles.insets.xs),
            const CircularProgressIndicator(),
          ],
          if (onAction != null) ...[
            SizedBox(height: $styles.insets.xs),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class const _OperationError(final String message) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      content: Text(message),
      leading: Icon(
        Icons.error_outline,
        color: Theme.of(context).colorScheme.error,
      ),
      actions: const [SizedBox.shrink()],
    );
  }
}

class const _BookmarkSelectionDialog({
  required final List<LocalBookmarkEntity> bookmarks,
}) extends StatefulWidget {
  @override
  State<_BookmarkSelectionDialog> createState() =>
      _BookmarkSelectionDialogState();
}

class _BookmarkSelectionDialogState() extends State<_BookmarkSelectionDialog> {
  final Set<int> _selected = <int>{};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    final viewport = MediaQuery.sizeOf(context);
    final dialogWidth = (viewport.width - 80).clamp(160.0, 460.0).toDouble();
    final dialogHeight = (viewport.height - 240).clamp(120.0, 360.0).toDouble();

    return AlertDialog(
      title: Text(l10n.addFavorite),
      content: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: ListView.builder(
          itemCount: widget.bookmarks.length,
          itemBuilder: (context, index) {
            final bookmark = widget.bookmarks[index];
            return CheckboxListTile(
              value: _selected.contains(bookmark.internalId),
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                bookmark.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onChanged: (selected) {
                setState(() {
                  if (selected == true) {
                    _selected.add(bookmark.internalId);
                  } else {
                    _selected.remove(bookmark.internalId);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.add)),
      ],
    );
  }

  void _submit() {
    Navigator.of(context).pop(
      widget.bookmarks
          .where((bookmark) => _selected.contains(bookmark.internalId))
          .toList(growable: false),
    );
  }
}

class const _CreatePlaylistDialog({
  required final List<MediaSourceDefinition> definitions,
  required final String? initialSourceId,
}) extends StatefulWidget {
  @override
  State<_CreatePlaylistDialog> createState() => _CreatePlaylistDialogState();
}

class _CreatePlaylistDialogState() extends State<_CreatePlaylistDialog> {
  late final TextEditingController _nameController;
  String? _sourceId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _sourceId =
        widget.definitions.any(
          (definition) => definition.id == widget.initialSourceId,
        )
        ? widget.initialSourceId
        : widget.definitions.first.id;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    return AlertDialog(
      title: Text(l10n.newPlaylist),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _sourceId,
            decoration: InputDecoration(labelText: l10n.source),
            items: [
              for (final definition in widget.definitions)
                DropdownMenuItem(
                  value: definition.id,
                  child: Text(definition.name),
                ),
            ],
            onChanged: (value) => setState(() => _sourceId = value),
          ),
          SizedBox(height: $styles.insets.sm),
          TextField(
            controller: _nameController,
            autofocus: true,
            maxLength: 60,
            decoration: InputDecoration(labelText: l10n.name),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.create)),
      ],
    );
  }

  void _submit() {
    final sourceId = _sourceId;
    final name = _nameController.text.trim();
    if (sourceId == null || name.isEmpty) return;
    Navigator.of(context).pop((sourceId: sourceId, name: name));
  }
}

Future<_PlaylistRequest?> _showCreatePlaylistDialog(
  BuildContext context, {
  required String? initialSourceId,
}) {
  final definitions = context.read<MediaSourceCatalog>().definitions;
  if (definitions.isEmpty) return Future.value();
  return showDialog<_PlaylistRequest>(
    context: context,
    builder: (_) => _CreatePlaylistDialog(
      definitions: definitions,
      initialSourceId: initialSourceId,
    ),
  );
}

class const _RenamePlaylistDialog({required final String initialName})
    extends StatefulWidget {
  @override
  State<_RenamePlaylistDialog> createState() => _RenamePlaylistDialogState();
}

class _RenamePlaylistDialogState() extends State<_RenamePlaylistDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    return AlertDialog(
      title: Text(l10n.renamePlaylistConfirm),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 60,
        decoration: InputDecoration(labelText: l10n.name),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(name);
  }
}

Future<String?> _showRenamePlaylistDialog(
  BuildContext context, {
  required String initialName,
}) => showDialog<String>(
  context: context,
  builder: (_) => _RenamePlaylistDialog(initialName: initialName),
);

class const _GroupDialog({required final String initialValue})
    extends StatefulWidget {
  @override
  State<_GroupDialog> createState() => _GroupDialogState();
}

class _GroupDialogState() extends State<_GroupDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    return AlertDialog(
      title: Text(l10n.setGroup),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 40,
        decoration: InputDecoration(
          labelText: l10n.groupName,
          hintText: l10n.groupNameHint,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }

  void _submit() => Navigator.of(context).pop(_controller.text.trim());
}

Future<String?> _showGroupDialog(
  BuildContext context, {
  required String initialValue,
}) => showDialog<String>(
  context: context,
  builder: (_) => _GroupDialog(initialValue: initialValue),
);

VideoModel _videoFromBookmark(LocalBookmarkEntity bookmark) => VideoModel(
  id: bookmark.originalId,
  title: bookmark.title,
  url: bookmark.url,
  thumbnailUrl: bookmark.thumbnailUrl,
  creatorProfileId: bookmark.creatorProfileId,
  creatorProfileName: bookmark.creatorProfileName,
);
