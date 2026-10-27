import 'dart:async';

import 'package:data/data.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';
import 'package:provider/provider.dart';

import '../../../data/repository/video_detail_repository.dart';
import '../../../datastore/preferences_data_source.dart';
import '../../../l10n/localization_file/app_localizations.dart';
import '../../../main.dart';
import '../bloc/video_bloc.dart';
import '../player/media_playback_controller.dart';

/// 画质按钮：显示当前清晰度，点击弹底部选择器。
///
/// 选中后以目标高度重新解析地址，用新流重开播放器并续接当前进度；
/// 同时把该高度记为默认画质，下次进入本视频自动套用。无
/// [PreferencesDataSource] 或 [VideoDetailRepository] 注入（widget 测试
/// 单独使用本组件）时只切换不记忆。
class const QualityPickerChip({
  super.key,
  required final MediaPlaybackController controller,
  required final MediaStream stream,
}) extends StatefulWidget {
  @override
  State<QualityPickerChip> createState() => _QualityPickerChipState();
}

class _QualityPickerChipState() extends State<QualityPickerChip> {
  bool _switching = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentLabel = _currentLabel(l10n);
    final qualityLabel = l10n?.qualitySelect ?? 'Quality';

    return Tooltip(
      message: qualityLabel,
      child: Semantics(
        button: true,
        enabled: !_switching,
        label: '$qualityLabel $currentLabel',
        excludeSemantics: true,
        child: Material(
          color: $styles.colors.scrim.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: _switching
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    _showQualityPicker(context);
                  },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: _switching
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: $styles.colors.onScrim,
                      ),
                    )
                  : Text(
                      currentLabel,
                      style: $styles.text.bodySmall.copyWith(
                        color: $styles.colors.onScrim,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  /// 当前档标签：与候选项取同一来源，保证列表标记与按钮文案一致。
  String _currentLabel(AppLocalizations? l10n) {
    final height = widget.stream.height;
    if (height == null) return l10n?.auto ?? 'Auto';
    return _heightLabel(height);
  }

  /// 高度 → 标签：先查候选列表里同高度的条目，取不到用 `{height}P`。
  String _heightLabel(int height) {
    for (final option in widget.stream.alternatives) {
      if (option.height == height) return option.label;
    }
    return '${height}P';
  }

  /// 弹窗里要列的全部档位：当前档 + 候选，按高度降序。
  List<MediaQualityOption> get _allOptions {
    final height = widget.stream.height;
    final current = height == null
        ? null
        : MediaQualityOption(
            height: height,
            label: _heightLabel(height),
            bitrate: widget.stream.bitrate,
          );
    final options = <MediaQualityOption>[...widget.stream.alternatives];
    if (current != null) options.add(current);
    options.sort((a, b) => b.height.compareTo(a.height));
    return options;
  }

  void _showQualityPicker(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final options = _allOptions;
    final currentHeight = widget.stream.height;

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: $styles.insets.sm),
                child: Text(
                  l10n?.qualitySelect ?? 'Quality',
                  style: $styles.text.bodySmallBold,
                ),
              ),
              if (options.isEmpty)
                ListTile(
                  title: Text(
                    l10n?.singleQualityOnly ?? 'Only one quality available',
                  ),
                ),
              for (final option in options)
                ListTile(
                  title: Text(option.label),
                  subtitle: option.bitrate == null
                      ? null
                      : Text(
                          '${(option.bitrate! / 1000000).toStringAsFixed(1)} Mbps',
                          style: $styles.text.bodySmall.copyWith(
                            color: $styles.colors.onSurfaceVariant,
                          ),
                        ),
                  trailing: _isCurrent(option, fallbackHeight: currentHeight)
                      ? Icon(Icons.check, color: $styles.colors.accentText)
                      : null,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(sheetContext).pop();
                    _applyQuality(option);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  /// 以目标高度重新解析地址，重开播放器并续接当前进度。
  Future<void> _applyQuality(MediaQualityOption option) async {
    final videoId = context.read<VideoBloc>().state.videoDetail?.video.id;
    if (videoId == null) return;
    if (_isCurrent(option)) return;

    setState(() => _switching = true);
    try {
      final repository = context.read<VideoDetailRepository>();
      final result = await repository.getMediaStream(
        videoId,
        preferHeight: option.height,
        preferStreamId: option.streamId,
      );
      if (!mounted) return;
      switch (result) {
        case Ok(:final value):
          // 续接：重开前把当前位置交给播放层，open 完成后自动 seek 回去。
          widget.controller.restorePositionSeconds =
              widget.controller.state.position.inSeconds;
          await widget.controller.open(value);
          if (!mounted) return;
          context.read<VideoBloc>().add(MediaStreamChanged(value));
          _persistDefaultQuality(option);
        case Error():
          break;
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  /// 档位是否就是当前在播的那一档。
  ///
  /// 有源侧 id 时按 id 比：同高度可能有多个码率，只看高度会把两档当成一档。
  bool _isCurrent(MediaQualityOption option, {int? fallbackHeight}) {
    if (option.streamId != null && widget.stream.streamId != null) {
      return option.streamId == widget.stream.streamId;
    }
    final height = option.height;
    return height == (fallbackHeight ?? widget.stream.height);
  }

  /// 把选中的整档记为默认画质。无 PreferencesDataSource 注入时跳过。
  ///
  /// id 与高度都写：id 用于精确匹配，高度留给源不认得该 id 的情况。
  void _persistDefaultQuality(MediaQualityOption option) {
    try {
      final preferences = context.read<PreferencesDataSource>();
      preferences.set(PreferencesKey.preferredQualityHeight, option.height);
      preferences.set(PreferencesKey.preferredQualityStreamId, option.streamId);
    } catch (_) {}
  }
}
