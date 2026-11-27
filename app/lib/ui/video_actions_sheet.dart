import 'dart:async';

import 'package:data/data.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../data/repository/local_library_repository.dart';
import '../design/design.dart';
import '../l10n/localization_file/app_localizations.dart';
import '../main.dart';

/// 视频卡片「更多」按钮打开的操作面板。
///
/// 平台侧的稍后观看要登录并向平台写数据，本项目是只读客户端，所以这里保存的
/// 是本地条目：与收藏分开存放，清空一个不会带走另一个。
class const VideoActionsSheet({
  super.key,
  required final String sourceId,
  required final VideoModel video,
}) extends StatefulWidget {
  /// 打开面板。`sourceId` 决定本地条目的归属来源。
  static Future<void> show(
    BuildContext context, {
    required String sourceId,
    required VideoModel video,
  }) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => VideoActionsSheet(sourceId: sourceId, video: video),
  );

  @override
  State<VideoActionsSheet> createState() => _VideoActionsSheetState();
}

class _VideoActionsSheetState() extends State<VideoActionsSheet> {
  /// null 表示还在读本地状态：读出来之前不给点，免得把「已在列表里」显示成
  /// 「保存」。
  bool? _saved;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    var saved = false;
    try {
      saved = await context.read<LocalLibraryRepository>().isInWatchLater(
        widget.sourceId,
        widget.video.id,
      );
    } on Object {
      // 读不出来就按「还没保存」处理：至少还能点，不会卡在灰掉的按钮上。
    }
    if (!mounted) return;
    setState(() => _saved = saved);
  }

  Future<void> _toggle() async {
    final saved = _saved;
    if (saved == null || _busy) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      await context.read<LocalLibraryRepository>().setWatchLater(
        sourceId: widget.sourceId,
        video: widget.video,
        saved: !saved,
      );
      unawaited(HapticFeedback.selectionClick());
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            saved ? l10n.removedFromWatchLater : l10n.savedToWatchLater,
          ),
        ),
      );
      navigator.pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final saved = _saved;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: $styles.insets.md),
            child: Text(
              widget.video.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: $styles.text.bodyBold,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            enabled: saved != null && !_busy,
            leading: Icon(
              saved == true ? AppIcons.watchLaterAdded : AppIcons.watchLater,
            ),
            title: Text(
              saved == true ? l10n.removeFromWatchLater : l10n.saveToWatchLater,
            ),
            onTap: _toggle,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
