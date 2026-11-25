import 'dart:async';

import 'package:data/data.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../design/design.dart';
import '../../l10n/localization_file/app_localizations.dart';

/// 重试按钮在限流后的冷静时长。
///
/// 风控窗口按分钟计，立刻重试只会再撞一次同样的拒绝；15 秒足够让用户读完
/// 提示，也足够让连续点击停下来。
const rateLimitRetryCooldown = Duration(seconds: 15);

/// 这次失败是否由源侧限流/风控引起。
///
/// 只认 `packages/data` 的中立契约；平台异常已由服务包适配成该契约。
bool isRateLimited(Object? error) => error is RateLimitedFailure;

/// 带冷静期的重试外壳。
///
/// [builder] 拿到文案、是否处于冷静期和当前回调：限流失败后在 [cooldown] 内
/// 回调为 `null`，文案变成倒计时；普通失败不进入冷静期。
class const RetryCooldownBuilder({
  super.key,
  required final bool rateLimited,
  required final VoidCallback onRetry,
  required final Widget Function(
    BuildContext context,
    String label,
    bool coolingDown,
    VoidCallback? onPressed,
  )
  builder,
  final Duration cooldown = rateLimitRetryCooldown,
}) extends StatefulWidget {
  @override
  State<RetryCooldownBuilder> createState() => _RetryCooldownBuilderState();
}

class _RetryCooldownBuilderState() extends State<RetryCooldownBuilder> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.rateLimited) _startCooldown();
  }

  @override
  void didUpdateWidget(RetryCooldownBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rateLimited && !oldWidget.rateLimited) _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    _remaining = widget.cooldown;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final next = _remaining - const Duration(seconds: 1);
      setState(() => _remaining = next.isNegative ? Duration.zero : next);
      if (_remaining == Duration.zero) timer.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final coolingDown = _remaining > Duration.zero;
    return widget.builder(
      context,
      coolingDown ? l10n.retryInSeconds(_remaining.inSeconds) : l10n.retry,
      coolingDown,
      coolingDown
          ? null
          : () {
              HapticFeedback.lightImpact();
              if (widget.rateLimited) setState(_startCooldown);
              widget.onRetry();
            },
    );
  }
}

/// 主按钮形态，用于首屏错误。
class const RetryCooldownButton({
  super.key,
  required final bool rateLimited,
  required final VoidCallback onRetry,
  final Duration cooldown = rateLimitRetryCooldown,
  final ButtonStyle? style,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => RetryCooldownBuilder(
    rateLimited: rateLimited,
    onRetry: onRetry,
    cooldown: cooldown,
    builder: (context, label, coolingDown, onPressed) =>
        FilledButton(style: style, onPressed: onPressed, child: Text(label)),
  );
}

/// 行内形态，用于翻页失败：刷新图标 + 文案。
class const RetryCooldownInlineButton({
  super.key,
  required final bool rateLimited,
  required final VoidCallback onRetry,

  /// 普通失败时的文案；冷静期内换成倒计时。
  required final String label,
  final Duration cooldown = rateLimitRetryCooldown,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => RetryCooldownBuilder(
    rateLimited: rateLimited,
    onRetry: onRetry,
    cooldown: cooldown,
    builder: (context, countdown, coolingDown, onPressed) => TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(AppIcons.refresh, size: 18),
      label: Text(coolingDown ? countdown : label),
    ),
  );
}
