import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/localization_file/app_localizations.dart';
import '../../../main.dart';
import '../bloc/queue_bloc.dart';

/// The source-scoped in-memory playback queue.
class const PlaybackQueueView({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => BlocBuilder<QueueBloc, QueueState>(
    builder: (context, state) {
      final l10n = AppLocalizations.of(context);
      return SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: Column(
            children: [
              _PlaybackQueueHeader(state: state),
              if (state.items.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      l10n?.playbackQueueEmpty ?? 'Your queue is empty',
                    ),
                  ),
                )
              else
                Expanded(
                  child: ReorderableListView.builder(
                    itemCount: state.items.length,
                    onReorderItem: (oldIndex, newIndex) {
                      context.read<QueueBloc>().add(
                        QueueMoveItem(oldIndex, newIndex),
                      );
                    },
                    itemBuilder: (context, index) => _PlaybackQueueItem(
                      key: ValueKey(
                        '${state.items[index].sourceId}:'
                        '${state.items[index].video.id}',
                      ),
                      item: state.items[index],
                      index: index,
                      length: state.items.length,
                      selected: index == state.currentIndex,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class const _PlaybackQueueHeader({required final QueueState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        $styles.insets.sm,
        $styles.insets.sm,
        $styles.insets.xs,
        $styles.insets.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${l10n?.playbackQueueTitle ?? 'Playback queue'} (${state.items.length})',
              style: $styles.text.title2.copyWith(
                color: $styles.colors.onSurfaceStrong,
              ),
            ),
          ),
          IconButton(
            tooltip: l10n?.playbackQueueClear ?? 'Clear queue',
            onPressed: state.items.isEmpty
                ? null
                : () => context.read<QueueBloc>().add(const QueueClear()),
            icon: const Icon(Icons.clear_all),
          ),
        ],
      ),
    );
  }
}

class const _PlaybackQueueItem({
  super.key,
  required final PlaybackQueueItem item,
  required final int index,
  required final int length,
  required final bool selected,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final queue = context.read<QueueBloc>();
    final title = item.video.title;
    return Material(
      color: selected
          ? $styles.colors.accentFill.withValues(alpha: 0.12)
          : $styles.colors.surface,
      child: ListTile(
        onTap: () => queue.add(QueueSelectItem(index)),
        leading: _thumbnail(item),
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: $styles.text.body.copyWith(
            color: selected
                ? $styles.colors.accentText
                : $styles.colors.onSurface,
            fontWeight: selected ? FontWeight.bold : null,
          ),
        ),
        subtitle: selected
            ? Text(
                l10n?.playbackQueuePlaying ?? 'Playing',
                style: $styles.text.bodySmall.copyWith(
                  color: $styles.colors.accentText,
                ),
              )
            : null,
        trailing: SizedBox(
          width: 144,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: l10n?.playbackQueueMoveUp ?? 'Move up',
                onPressed: index == 0
                    ? null
                    : () => queue.add(QueueMoveItem(index, index - 1)),
                icon: const Icon(Icons.keyboard_arrow_up),
              ),
              IconButton(
                tooltip: l10n?.playbackQueueMoveDown ?? 'Move down',
                onPressed: index == length - 1
                    ? null
                    : () => queue.add(QueueMoveItem(index, index + 1)),
                icon: const Icon(Icons.keyboard_arrow_down),
              ),
              IconButton(
                tooltip: l10n?.playbackQueueRemove ?? 'Remove from queue',
                onPressed: () => queue.add(QueueRemoveItem(index)),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbnail(PlaybackQueueItem item) {
    final url = item.video.thumbnailUrl;
    return SizedBox(
      width: 80,
      height: 45,
      child: ClipRRect(
        borderRadius: BorderRadius.circular($styles.corners.sm),
        child: url == null || url.isEmpty
            ? ColoredBox(
                color: $styles.colors.surfaceContainerHighest,
                child: Icon(
                  Icons.play_circle_outline,
                  color: $styles.colors.onSurfaceVariant,
                ),
              )
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                errorBuilder: (context, url, error) => Icon(
                  Icons.play_circle_outline,
                  color: $styles.colors.onSurfaceVariant,
                ),
              ),
      ),
    );
  }
}
