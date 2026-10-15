import 'package:data/data.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/repository/local_library_repository.dart';
import '../../database/app_database.dart';
import '../../main.dart';

/// Shows the local playlists that belong to [sourceId] and appends [video] to
/// the selected playlist. A new playlist can be created from the same dialog.
///
/// The dialog only closes after the repository confirms the append. Database
/// failures remain visible in the dialog so a failed write cannot look like a
/// successful playlist action.
Future<void> showLocalPlaylistPicker(
  BuildContext context, {
  required String sourceId,
  required VideoModel video,
}) async {
  if (!context.mounted) return;
  final repository = context.read<LocalLibraryRepository>();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => _LocalPlaylistPickerDialog(
      repository: repository,
      sourceId: sourceId,
      video: video,
    ),
  );
}

class const _LocalPlaylistPickerDialog({
  required final LocalLibraryRepository repository,
  required final String sourceId,
  required final VideoModel video,
}) extends StatefulWidget {
  @override
  State<_LocalPlaylistPickerDialog> createState() =>
      _LocalPlaylistPickerDialogState();
}

class _LocalPlaylistPickerDialogState()
    extends State<_LocalPlaylistPickerDialog> {
  late Stream<List<LocalPlaylistEntity>> _playlists;
  String? _error;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _playlists = widget.repository.watchPlaylists();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加到播放列表'),
      content: SizedBox(
        width: 420,
        child: StreamBuilder<List<LocalPlaylistEntity>>(
          stream: _playlists,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return _PickerMessage(
                message: '播放列表加载失败',
                actionLabel: '重试',
                onAction: _retry,
              );
            }

            final playlists = (snapshot.data ?? const <LocalPlaylistEntity>[])
                .where((playlist) => playlist.sourceId == widget.sourceId)
                .toList(growable: false);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error case final error?) ...[
                  Text(
                    error,
                    style: $styles.text.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  SizedBox(height: $styles.insets.xs),
                ],
                if (playlists.isEmpty)
                  const _PickerMessage(message: '还没有播放列表')
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 360),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: playlists.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final playlist = playlists[index];
                        return Tooltip(
                          message: '添加到 ${playlist.name}',
                          child: Semantics(
                            button: true,
                            enabled: !_isSaving,
                            label: '添加到播放列表 ${playlist.name}',
                            child: ListTile(
                              enabled: !_isSaving,
                              leading: const Icon(Icons.queue_music_outlined),
                              title: Text(playlist.name),
                              onTap: () {
                                HapticFeedback.lightImpact();
                                _appendTo(playlist);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                SizedBox(height: $styles.insets.xs),
                OutlinedButton.icon(
                  onPressed: _isSaving
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          _createPlaylist();
                        },
                  icon: const Icon(Icons.add),
                  label: const Text('新建播放列表'),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ],
    );
  }

  void _retry() {
    if (!mounted) return;
    setState(() {
      _playlists = widget.repository.watchPlaylists();
      _error = null;
    });
  }

  Future<void> _appendTo(LocalPlaylistEntity playlist) async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await widget.repository.addToPlaylist(
        playlistId: playlist.internalId,
        sourceId: widget.sourceId,
        video: widget.video,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = '添加失败：$error';
      });
    }
  }

  Future<void> _createPlaylist() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final name = await _showPlaylistNameDialog(context);
    if (!mounted) return;
    if (name == null) {
      setState(() => _isSaving = false);
      return;
    }
    try {
      final playlistId = await widget.repository.createPlaylist(
        widget.sourceId,
        name,
      );
      await widget.repository.addToPlaylist(
        playlistId: playlistId,
        sourceId: widget.sourceId,
        video: widget.video,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = '创建或添加失败：$error';
      });
    }
  }
}

class const _PickerMessage({
  required final String message,
  final String? actionLabel,
  final VoidCallback? onAction,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: $styles.insets.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: $styles.text.body.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (onAction != null) ...[
            SizedBox(height: $styles.insets.xs),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

Future<String?> _showPlaylistNameDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (_) => const _PlaylistNameDialog(),
  );
}

class const _PlaylistNameDialog() extends StatefulWidget {
  @override
  State<_PlaylistNameDialog> createState() => _PlaylistNameDialogState();
}

class _PlaylistNameDialogState() extends State<_PlaylistNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新建播放列表'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 60,
        decoration: const InputDecoration(
          labelText: '名称',
          hintText: '请输入播放列表名称',
        ),
        onSubmitted: (_) {
          HapticFeedback.lightImpact();
          _submit();
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            _submit();
          },
          child: const Text('创建'),
        ),
      ],
    );
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(name);
  }
}
