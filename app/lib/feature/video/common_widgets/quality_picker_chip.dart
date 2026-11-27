import 'dart:async';

import 'package:data/data.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';
import 'package:provider/provider.dart';

import '../../../data/repository/video_detail_repository.dart';
import '../../../datastore/preferences_data_source.dart';
import '../../../design/design.dart';
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
    // `excludeSemantics: true` drops the InkWell's tap action, so the same
    // callback has to be declared on the Semantics node as well.
    final openPicker = _switching
        ? null
        : () {
            HapticFeedback.lightImpact();
            _showQualityPicker(context);
          };

    return Tooltip(
      message: qualityLabel,
      child: Semantics(
        button: true,
        enabled: openPicker != null,
        label: '$qualityLabel $currentLabel',
        onTap: openPicker,
        excludeSemantics: true,
        child: Material(
          color: $styles.colors.scrim.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: openPicker,
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
    final qualityLabel = widget.stream.qualityLabel;
    if (qualityLabel != null && qualityLabel.isNotEmpty) return qualityLabel;
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
  ///
  /// 列表行只展示标签、码率，必要时补编码/帧率。同一档位可能在候选里重复
  /// 出现（实测一个视频有三行「流畅 360P 0.2 Mbps」），码率经一位小数格式化
  /// 后相同、且编码与帧率也相同的行对用户完全不可区分，因此按「渲染结果」
  /// 去重；若重复项里包含当前在播的那一档，保留它，保证勾选标记落在正确行。
  List<MediaQualityOption> get _allOptions {
    final height = widget.stream.height;
    final current = height == null
        ? null
        : MediaQualityOption(
            height: height,
            label: _currentLabel(AppLocalizations.of(context)),
            streamId: widget.stream.streamId,
            bitrate: widget.stream.bitrate,
            codecs: widget.stream.codecs,
            frameRate: widget.stream.frameRate,
          );
    final options = <MediaQualityOption>[...widget.stream.alternatives];
    if (current != null) options.add(current);
    options.sort(_compareOptions);

    final deduped = <MediaQualityOption>[];
    final indexByRenderedRow = <String, int>{};
    for (final option in options) {
      final key = _renderedRowKey(option);
      final existingIndex = indexByRenderedRow[key];
      if (existingIndex == null) {
        indexByRenderedRow[key] = deduped.length;
        deduped.add(option);
      } else if (_isCurrent(option) && !_isCurrent(deduped[existingIndex])) {
        deduped[existingIndex] = option;
      }
    }
    // 替换成当前档可能改变该行的高度，去重后重新排序。
    deduped.sort(_compareOptions);
    return deduped;
  }

  /// 高度降序；同高度按码率降序，让高码率档排在前面且顺序稳定。
  static int _compareOptions(MediaQualityOption a, MediaQualityOption b) {
    final byHeight = (b.height ?? 0).compareTo(a.height ?? 0);
    if (byHeight != 0) return byHeight;
    return (b.bitrate ?? 0).compareTo(a.bitrate ?? 0);
  }

  /// 一行实际渲染出来的内容：标签 + 码率文案 + 编码 + 帧率。
  ///
  /// 码率取格式化后的文案而不是原始值：119861 与 105025 都显示为
  /// 「0.1 Mbps」，用原始值做键会让两行看起来一样的选项同时留下。
  static String _renderedRowKey(MediaQualityOption option) => [
    option.label,
    _bitrateLabel(option.bitrate) ?? '',
    _codecLabel(option.codecs) ?? '',
    option.frameRate?.trim() ?? '',
  ].join('\u0000');

  static String? _bitrateLabel(int? bitrate) =>
      bitrate == null ? null : '${(bitrate / 1000000).toStringAsFixed(1)} Mbps';

  /// 编码标识归一成用户认得的名字；未知编码原样显示。
  static String? _codecLabel(String? codecs) {
    final value = codecs?.trim();
    if (value == null || value.isEmpty) return null;
    final lower = value.toLowerCase();
    if (lower.startsWith('avc') || lower.startsWith('h264')) return 'AVC';
    if (lower.startsWith('hev') ||
        lower.startsWith('hvc') ||
        lower.startsWith('h265')) {
      return 'HEVC';
    }
    if (lower.startsWith('av01') || lower.startsWith('av1')) return 'AV1';
    return value;
  }

  static String? _frameRateLabel(String? frameRate) {
    final value = frameRate?.trim();
    if (value == null || value.isEmpty) return null;
    return '$value fps';
  }

  /// 行副标题：码率必显；同一标签有多行时再补编码与帧率，用来区分同高度
  /// 的多路流。
  static String? _optionSubtitle(
    MediaQualityOption option, {
    required bool distinguish,
  }) {
    final bitrate = _bitrateLabel(option.bitrate);
    final codec = distinguish ? _codecLabel(option.codecs) : null;
    final fps = distinguish ? _frameRateLabel(option.frameRate) : null;
    final parts = <String>[?bitrate, ?codec, ?fps];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  void _showQualityPicker(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final options = _allOptions;
    final currentHeight = widget.stream.height;
    final labelCounts = <String, int>{};
    for (final option in options) {
      labelCounts.update(option.label, (count) => count + 1, ifAbsent: () => 1);
    }

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                // 与 Material ListTile 的固定内容内边距对齐，不随布局尺度缩放（R2.4）。
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: $styles.insets.sm,
                ),
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
                  subtitle: switch (_optionSubtitle(
                    option,
                    distinguish: (labelCounts[option.label] ?? 0) > 1,
                  )) {
                    final text? => Text(
                      text,
                      style: $styles.text.bodySmall.copyWith(
                        color: $styles.colors.onSurfaceVariant,
                      ),
                    ),
                    null => null,
                  },
                  trailing: _isCurrent(option, fallbackHeight: currentHeight)
                      ? Icon(AppIcons.check, color: $styles.colors.accentText)
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
        case Success(:final success):
          // 续接：由 _VideoSurface 在收到新状态后统一重开播放器，避免这里
          // 先 open 一次、状态更新触发 didUpdateWidget 又 open 一次。
          widget.controller.restorePositionSeconds =
              widget.controller.state.position.inSeconds;
          context.read<VideoBloc>().add(MediaStreamChanged(success));
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
