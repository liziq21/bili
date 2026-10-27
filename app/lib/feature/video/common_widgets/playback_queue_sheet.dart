import 'dart:async';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/localization_file/app_localizations.dart';
import '../../../l10n/localization_file/app_localizations_zh.dart';
import '../../../main.dart';
import '../player/media_playback_controller.dart';

/// Opens the queue as a bottom sheet without making the player page own sheet
/// state.
Future<void> showPlaybackQueueSheet(
  BuildContext context, {
  required MediaPlaybackController controller,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PlaybackQueueSheet(controller: controller),
  );
}

/// A compact, editable view of the current playback queue.
///
/// Tapping an item starts it immediately. Non-current items can be removed or
/// reordered with the drag handle; the current item stays in the queue so the
/// player always has a visible source of truth for what is playing.
class const PlaybackQueueSheet({
  required final MediaPlaybackController controller,
  super.key,
}) extends StatefulWidget {
  @override
  State<PlaybackQueueSheet> createState() => _PlaybackQueueSheetState();
}

class _PlaybackQueueSheetState() extends State<PlaybackQueueSheet> {
  late List<PlaybackQueueItem> _items;
  PlaybackState _playbackState = _initialState();
  StreamSubscription<List<PlaybackQueueItem>>? _queueSubscription;
  StreamSubscription<PlaybackState>? _stateSubscription;

  static PlaybackState _initialState() => PlaybackState(
    isPlaying: false,
    isBuffering: false,
    position: Duration.zero,
    duration: Duration.zero,
  );

  @override
  void initState() {
    super.initState();
    _items = widget.controller.queueItems;
    _playbackState = widget.controller.state;
    _queueSubscription = widget.controller.queueItemStates.listen((items) {
      if (!mounted) return;
      setState(() => _items = items);
    });
    _stateSubscription = widget.controller.states.listen((state) {
      if (!mounted) return;
      setState(() => _playbackState = state);
    });
  }

  @override
  void dispose() {
    _queueSubscription?.cancel();
    _stateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    final size = MediaQuery.sizeOf(context);
    final maxHeight = size.height * .82;

    return SafeArea(
      top: false,
      child: Material(
        color: $styles.colors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular($styles.corners.lg),
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _QueueHeader(
                title: l10n.playbackQueue,
                countLabel: l10n.playbackQueueCount(_items.length),
                mode: _playbackState.queueMode,
                onModeChanged: _cycleMode,
                onClose: () => Navigator.of(context).pop(),
              ),
              Divider(
                height: 1,
                color: $styles.colors.outline.withValues(alpha: 0.2),
              ),
              if (_items.isEmpty)
                _EmptyQueue(message: l10n.queueEmpty)
              else
                Flexible(
                  child: ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    padding: EdgeInsets.symmetric(vertical: $styles.insets.xs),
                    itemCount: _items.length,
                    onReorderItem: _reorder,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return _QueueItemTile(
                        key: ValueKey('${item.stream.videoUrl}-$index'),
                        index: index,
                        item: item,
                        isCurrent: index == _playbackState.currentIndex,
                        onTap: () => _play(index),
                        onRemove: index == _playbackState.currentIndex
                            ? null
                            : () => _remove(index),
                        dragHandle: ReorderableDragStartListener(
                          index: index,
                          child: Icon(
                            Icons.drag_handle,
                            color: $styles.colors.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _cycleMode() {
    final nextMode = switch (_playbackState.queueMode) {
      PlaybackQueueMode.none => PlaybackQueueMode.single,
      PlaybackQueueMode.single => PlaybackQueueMode.loop,
      PlaybackQueueMode.loop => PlaybackQueueMode.none,
    };
    HapticFeedback.selectionClick();
    unawaited(widget.controller.setQueueMode(nextMode));
  }

  void _play(int index) {
    HapticFeedback.lightImpact();
    unawaited(widget.controller.jumpTo(index));
  }

  void _remove(int index) {
    HapticFeedback.lightImpact();
    unawaited(widget.controller.removeFromQueue(index));
  }

  void _reorder(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    HapticFeedback.selectionClick();
    unawaited(widget.controller.moveQueueItem(oldIndex, newIndex));
  }
}

class const _QueueHeader({
  required final String title,
  required final String countLabel,
  required final PlaybackQueueMode mode,
  required final VoidCallback onModeChanged,
  required final VoidCallback onClose,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        $styles.insets.sm,
        $styles.insets.sm,
        $styles.insets.xs,
        $styles.insets.xs,
      ),
      child: Row(
        children: [
          Icon(Icons.queue_music, color: $styles.colors.accentFill),
          SizedBox(width: $styles.insets.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: $styles.text.bodyBold.copyWith(
                    color: $styles.colors.onSurfaceStrong,
                  ),
                ),
                Text(
                  countLabel,
                  style: $styles.text.bodySmall.copyWith(
                    color: $styles.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: _modeTooltip(l10n, mode),
            onPressed: onModeChanged,
            icon: Icon(_modeIcon(mode)),
          ),
          IconButton(
            tooltip: l10n.cancel,
            onPressed: onClose,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  String _modeTooltip(AppLocalizations l10n, PlaybackQueueMode mode) {
    return switch (mode) {
      PlaybackQueueMode.none => l10n.loopOff,
      PlaybackQueueMode.single => l10n.loopOne,
      PlaybackQueueMode.loop => l10n.loopQueue,
    };
  }

  IconData _modeIcon(PlaybackQueueMode mode) {
    return switch (mode) {
      PlaybackQueueMode.none => Icons.repeat,
      PlaybackQueueMode.single => Icons.repeat_one,
      PlaybackQueueMode.loop => Icons.repeat,
    };
  }
}

class const _QueueItemTile({
  required super.key,
  required final int index,
  required final PlaybackQueueItem item,
  required final bool isCurrent,
  required final VoidCallback onTap,
  required final VoidCallback? onRemove,
  required final Widget dragHandle,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    final title = item.title ?? l10n.queueItemFallback(index + 1);
    final creator = item.creatorName;
    final semanticLabel = isCurrent
        ? '$title, ${l10n.currentlyPlaying}'
        : title;

    return Semantics(
      button: true,
      selected: isCurrent,
      label: semanticLabel,
      child: ListTile(
        selected: isCurrent,
        selectedTileColor: $styles.colors.accentFill.withValues(alpha: 0.1),
        onTap: onTap,
        leading: _QueueThumbnail(item: item, isCurrent: isCurrent),
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: $styles.text.bodySmall.copyWith(
            color: isCurrent
                ? $styles.colors.accentText
                : $styles.colors.onSurfaceStrong,
            fontWeight: isCurrent ? FontWeight.w600 : null,
          ),
        ),
        subtitle: creator == null
            ? null
            : Text(
                creator,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: $styles.text.caption.copyWith(
                  color: $styles.colors.onSurfaceVariant,
                ),
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onRemove != null)
              IconButton(
                tooltip: l10n.removeFromQueue,
                onPressed: onRemove,
                icon: const Icon(Icons.remove_circle_outline),
              ),
            SizedBox(width: 40, child: Center(child: dragHandle)),
          ],
        ),
      ),
    );
  }
}

class const _QueueThumbnail({
  required final PlaybackQueueItem item,
  required final bool isCurrent,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = item.thumbnailUrl;
    final image = thumbnailUrl == null || thumbnailUrl.isEmpty
        ? const Icon(Icons.play_circle_outline)
        : CachedNetworkImage(
            imageUrl: thumbnailUrl,
            fit: BoxFit.cover,
            memCacheWidth: 160,
            errorBuilder: (context, url, error) =>
                const Icon(Icons.play_circle_outline),
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular($styles.corners.sm),
      child: ColoredBox(
        color: $styles.colors.surfaceContainerHighest,
        child: SizedBox(
          width: 64,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconTheme(
                data: IconThemeData(
                  color: isCurrent
                      ? $styles.colors.accentFill
                      : $styles.colors.onSurfaceVariant,
                ),
                child: image,
              ),
              if (isCurrent)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Icon(
                    Icons.equalizer,
                    size: 14,
                    color: $styles.colors.accentFill,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class const _EmptyQueue({required final String message})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all($styles.insets.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.queue_music_outlined,
            size: 40,
            color: $styles.colors.onSurfaceVariant,
          ),
          SizedBox(height: $styles.insets.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: $styles.text.body.copyWith(
              color: $styles.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
