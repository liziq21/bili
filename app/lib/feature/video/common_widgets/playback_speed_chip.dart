import 'dart:async';

import '../../../datastore/preferences_data_source.dart';
import '../../setting/app_settings.dart' as settings;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../l10n/localization_file/app_localizations.dart';
import '../../../main.dart';
import '../player/media_playback_controller.dart';

/// 长按临时加速的目标倍速。
const double kBoostRate = 2.0;

/// Backwards-compatible export for the player chip's rate list.
const kPlaybackRates = settings.kPlaybackRates;

/// 把倍速值格式成短标签：1.0 → "1x"，1.5 → "1.5x"，0.75 → "0.75x"。
String rateLabel(double rate) => settings.playbackRateLabel(rate);

/// 倍速按钮：显示当前倍速，点击弹底部选择器。
///
/// 选择后立即套用到播放器，并写入 preferences 记为默认倍速；
/// 无 PreferencesDataSource 注入（widget 测试单独使用）时只套用不记忆。
class const PlaybackSpeedChip({
  required final MediaPlaybackController controller,
  super.key,
}) extends StatefulWidget {
  @override
  State<PlaybackSpeedChip> createState() => _PlaybackSpeedChipState();
}

class _PlaybackSpeedChipState() extends State<PlaybackSpeedChip> {
  StreamSubscription<PlaybackState>? _subscription;
  double _rate = 1.0;

  @override
  void initState() {
    super.initState();
    _subscription = widget.controller.states.listen((state) {
      if (!mounted) return;
      setState(() => _rate = state.rate);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentText = rateLabel(_rate);
    final speedLabel = l10n?.playbackSpeed ?? 'Speed';

    return Tooltip(
      message: speedLabel,
      child: Semantics(
        button: true,
        label: '$speedLabel $currentText',
        excludeSemantics: true,
        child: Material(
          color: $styles.colors.scrim.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              _showSpeedPicker(context);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(
                currentText,
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

  void _showSpeedPicker(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                  l10n?.playbackSpeed ?? 'Speed',
                  style: $styles.text.bodySmallBold,
                ),
              ),
              for (final rate in kPlaybackRates)
                ListTile(
                  title: Text(rateLabel(rate)),
                  trailing: rate == _rate
                      ? Icon(Icons.check, color: $styles.colors.accentText)
                      : null,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.controller.setRate(rate);
                    _persistRate(rate);
                    Navigator.of(sheetContext).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  /// 把选中倍速记为默认。无 PreferencesDataSource 注入时跳过。
  void _persistRate(double rate) {
    try {
      context.read<PreferencesDataSource>().set(
        PreferencesKey.playbackRate,
        rate,
      );
    } catch (_) {}
  }
}

/// 长按 2x 的状态机：记录按住前的倍速，松开后恢复。
///
/// 单独存在是为了让手势回调可以被单元测试直接驱动，不必渲染
/// `Video`（真 `VideoController` 在有 libmpv 的环境会走原生 ffi）。
class BoostRateController(final MediaPlaybackController _controller)
    extends ChangeNotifier {
  bool _boosted = false;
  double? _rateBeforeBoost;

  /// 是否处于长按加速中（控制 "2x" 标记显隐）。
  bool get boosted => _boosted;

  /// 长按按下：切到 [kBoostRate]，记住松开后要恢复的倍速。
  void onLongPress() {
    HapticFeedback.mediumImpact();
    _rateBeforeBoost = _controller.state.rate;
    _controller.setRate(kBoostRate);
    _boosted = true;
    notifyListeners();
  }

  /// 长按松开：恢复按下前记住的倍速。
  ///
  /// [_rateBeforeBoost] 由 [onLongPress] 保证非空（[PlaybackState.rate] 有初值）。
  void onLongPressEnd() {
    _boosted = false;
    final previous = _rateBeforeBoost;
    if (previous != null) {
      _controller.setRate(previous);
    }
    notifyListeners();
  }
}
