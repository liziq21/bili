import 'package:data/data.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../app_scaffold.dart';
import '../../l10n/localization_file/app_localizations.dart';
import 'bloc/live_bloc.dart';

/// 直播画质按钮：显示当前清晰度，点击弹底部选择器。
///
/// 选中后以目标 qn 重新请求流地址（换流重开由 live_screen 监听
/// mediaStream 变化触发），并把该 qn 记为该房间的上次选择（bloc 负责
/// 落偏好）。与点播的 QualityPickerChip 分开：直播档以 qn 为身份、无
/// 画面高度、记忆按房间而非全局。
class const LiveQualityChip({
  super.key,
  required final MediaStream stream,
  required final int roomId,
}) extends StatefulWidget {
  @override
  State<LiveQualityChip> createState() => _LiveQualityChipState();
}

class _LiveQualityChipState() extends State<LiveQualityChip> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final qualityLabel = l10n?.qualitySelect ?? 'Quality';
    final switching = context.select<LiveBloc, bool>(
      (bloc) => bloc.state.isSwitchingQuality,
    );
    final currentLabel = widget.stream.qualityLabel ?? l10n?.auto ?? 'Auto';

    return Tooltip(
      message: qualityLabel,
      child: Semantics(
        button: true,
        enabled: !switching,
        label: '$qualityLabel $currentLabel',
        excludeSemantics: true,
        child: Material(
          color: $styles.colors.scrim.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: switching
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    _showQualityPicker(context);
                  },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: switching
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

  /// 弹窗里要列的全部档位：当前档置顶（勾选），其余按源侧顺序。
  List<MediaQualityOption> get _allOptions {
    final l10n = AppLocalizations.of(context);
    final stream = widget.stream;
    final current = MediaQualityOption(
      streamId: stream.streamId,
      label: stream.qualityLabel ?? l10n?.auto ?? 'Auto',
    );
    return [current, ...stream.alternatives];
  }

  void _showQualityPicker(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final options = _allOptions;
    final stream = widget.stream;

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
              if (options.length <= 1)
                ListTile(
                  title: Text(
                    l10n?.singleQualityOnly ?? 'Only one quality available',
                  ),
                ),
              for (final option in options)
                ListTile(
                  title: Text(option.label),
                  trailing: option.streamId == stream.streamId
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

  /// 以目标 qn 重新请求流地址。与当前档相同则不发事件。
  void _applyQuality(MediaQualityOption option) {
    final targetQn = option.streamId;
    if (targetQn == null || targetQn == widget.stream.streamId) return;
    context.read<LiveBloc>().add(SwitchLiveQuality(widget.roomId, targetQn));
  }
}
