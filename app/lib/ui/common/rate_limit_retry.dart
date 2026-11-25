import 'dart:async';

import 'package:bilibili/bilibili.dart' show BiliRiskControlException;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/localization_file/app_localizations.dart';

/// 请求是否被源侧风控/限流拒绝（HTTP 412、`code: -352`、只剩 `v_voucher`）。
///
/// 这类失败和网络故障不是一回事：数据源没坏，只是此刻不让取，等一会儿重试
/// 就能恢复。界面据此换文案，并让「重试」先冷静一段时间再可用。
bool isRateLimited(Object? error) => error is BiliRiskControlException;

/// 风控失败后「重试」保持禁用的时长。
const Duration rateLimitRetryCooldown = Duration(seconds: 15);

/// 带冷静期的重试按钮。
///
/// 风控窗口内连点重试只会连续撞同一堵墙，所以被风控拒绝后先禁用一段时
/// 间，按钮文案显示剩余秒数，冷却结束自动恢复可用。
class const RetryCooldownButton({
  super.key,

  /// 上一次失败是否由风控引起；只有风控才进入冷静期。
  required final bool rateLimited,
  required final VoidCallback onRetry,
  final Duration cooldown = rateLimitRetryCooldown,
  final ButtonStyle? style,
}) extends StatefulWidget {
  @override
  State<RetryCooldownButton> createState() => _RetryCooldownButtonState();
}

class _RetryCooldownButtonState() extends State<RetryCooldownButton> {
  Timer? _ticker;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.rateLimited) _startCooldown();
  }

  @override
  void didUpdateWidget(RetryCooldownButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rateLimited && !oldWidget.rateLimited) _startCooldown();
    if (!widget.rateLimited && oldWidget.rateLimited) _stopCooldown();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _ticker?.cancel();
    _remaining = widget.cooldown;
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final next = _remaining - const Duration(seconds: 1);
      setState(() => _remaining = next.isNegative ? Duration.zero : next);
      if (_remaining == Duration.zero) timer.cancel();
    });
  }

  void _stopCooldown() {
    _ticker?.cancel();
    _ticker = null;
    _remaining = Duration.zero;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final coolingDown = _remaining > Duration.zero;
    final seconds = _remaining.inSeconds;
    return FilledButton(
      style: widget.style,
      onPressed: coolingDown
          ? null
          : () {
              HapticFeedback.lightImpact();
              if (widget.rateLimited) setState(_startCooldown);
              widget.onRetry();
            },
      child: Text(
        coolingDown
            ? l10n?.retryInSeconds(seconds) ?? 'Retry in ${seconds}s'
            : l10n?.retry ?? 'Retry',
      ),
    );
  }
}
