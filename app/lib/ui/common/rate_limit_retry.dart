import 'dart:async';

import 'package:data/data.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../design/design.dart';
import '../../l10n/localization_file/app_localizations.dart';

/// 首次被限流后的冷静时长。
///
/// 风控窗口按分钟计，立刻重试只会再撞一次同样的拒绝；15 秒足够让用户读完
/// 提示，也足够让连续点击停下来。
const rateLimitRetryBaseCooldown = Duration(seconds: 15);

/// 连续被限流时冷却时间的上限。
const rateLimitRetryMaxCooldown = Duration(minutes: 5);

/// 一个 scope 的连续被拒记录：次数与最后一次被拒的时间。
final class _Streak(final int count, final DateTime at);

final _streaks = <String, _Streak>{};

/// 每个 scope 上一次看到的拒绝对象与时间。
///
/// 错误视图在重试时可能被 loading 态替换后**重新挂载**（频道页、创作者档案），
/// 也可能原地重建（搜索结果）。只比较对象身份就能区分「同一次拒绝的重新
/// 挂载」与「重试后又被拒」：平台适配层每次拒绝都会构造新的异常实例，而
/// 切走再回来沿用 bloc 里同一个错误对象。
final _lastFailures = <String, _SeenFailure>{};

final class _SeenFailure(final Object? failure, final DateTime at);

/// [Object] 没有值语义，用作「还没有记录过」与 `failure == null` 的哨兵。
const _noFailure = Object();

/// 连续被拒之间隔得比这还久，就当新的一轮，不再沿用旧次数。
///
/// 必须明显大于 [rateLimitRetryMaxCooldown]：冷却到上限后用户会等满 5 分钟
/// 再重试，若 TTL 与上限相等，这一次失败会被当成新的一轮，冷却从上限跌回
/// 基础时长——持续限流时反而越等越短。
final _streakTtl = rateLimitRetryMaxCooldown * 2;

/// 记一次新的限流失败，返回按 2 的幂放大后的冷却时长。
///
/// 固定 15 秒只挡得住连点；连着被拒说明风控窗口还没过去，必须把间隔拉开，
/// 否则重试永远是同一堵墙。
Duration rateLimitCooldownFor(String scope) =>
    _backoff(_recordFailure(scope, escalate: true));

/// 成功或换成别的失败原因后清零，避免冷却被历史失败永久拉长。
void resetRateLimitCooldown(String scope) {
  _streaks.remove(scope);
  _lastFailures.remove(scope);
}

/// 清空全部冷却记录，仅供测试隔离：连击表是进程级状态，会跨用例累积。
@visibleForTesting
void resetAllRateLimitCooldowns() {
  _streaks.clear();
  _lastFailures.clear();
}

/// 这次挂载带来的拒绝对象是不是该 scope 之前没见过的「新一次拒绝」。
///
/// 第一次看到某个 scope 返回 false：只登记、不放大，否则首次进入就会从
/// 双倍冷却起步。之后对象身份不同、且上一次拒绝仍在 [_streakTtl] 内，才算
/// 新的一次。
bool _isNewFailure(String scope, Object? failure) {
  final previous = _lastFailures[scope];
  if (previous == null) return false;
  if (DateTime.now().difference(previous.at) > _streakTtl) return false;
  return !identical(previous.failure ?? _noFailure, failure ?? _noFailure);
}

void _rememberFailure(String scope, Object? failure) {
  final now = DateTime.now();
  // 顺带清掉过期 scope，避免长时间运行后按 scope 无限累积。
  _lastFailures.removeWhere((_, seen) => now.difference(seen.at) > _streakTtl);
  _lastFailures[scope] = _SeenFailure(failure, now);
}

/// 记下这次被拒。[escalate] 为 false 时只登记、不放大——界面重建会把同
/// 一次拒绝再报一遍，那不是新的一次。
int _recordFailure(String scope, {required bool escalate}) {
  final now = DateTime.now();
  final current = _streaks[scope];
  final fresh = current != null && now.difference(current.at) <= _streakTtl;
  if (!fresh) {
    _streaks[scope] = _Streak(1, now);
    return 1;
  }
  if (!escalate) return current.count;
  final streak = _Streak(current.count + 1, now);
  _streaks[scope] = streak;
  return streak.count;
}

Duration _backoff(int strike) {
  final seconds =
      rateLimitRetryBaseCooldown.inSeconds * (1 << (strike - 1).clamp(0, 6));
  return seconds >= rateLimitRetryMaxCooldown.inSeconds
      ? rateLimitRetryMaxCooldown
      : Duration(seconds: seconds);
}

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

  /// 冷却计数的分组，通常一个重试入口一个 scope。
  final String scope = 'default',

  /// 显式指定固定冷却时长，仅测试使用；为 null 时按 [rateLimitCooldownFor]
  /// 逐次放大。
  final Duration? cooldown,

  /// 这次失败本身。换了对象就说明又收到一次拒绝，要放大冷却；界面重建带来
  /// 的同一个对象不算新的一次。
  final Object? failure,
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
    if (widget.rateLimited) {
      // 错误视图可能在重试时被 loading 态替换后重新挂载。第一次看到这个
      // scope 只登记、不放大；带着新的拒绝对象重新挂载才算「重试后又被拒」，
      // 按新的连击数拉长间隔。带着同一个对象回来（切走再回来）不放大。
      final isNew = _isNewFailure(widget.scope, widget.failure);
      _rememberFailure(widget.scope, widget.failure);
      _startCooldown(_resolveCooldown(escalate: isNew));
    } else {
      resetRateLimitCooldown(widget.scope);
    }
  }

  @override
  void didUpdateWidget(RetryCooldownBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rateLimited) {
      // 重试后又被拒：换了一个失败对象才算新的一次，按新的连击数拉长间隔。
      if (!oldWidget.rateLimited ||
          !identical(widget.failure, oldWidget.failure)) {
        _rememberFailure(widget.scope, widget.failure);
        _startCooldown(_resolveCooldown(escalate: true));
      }
    } else {
      resetRateLimitCooldown(widget.scope);
    }
  }

  Duration _resolveCooldown({required bool escalate}) {
    final fixed = widget.cooldown;
    if (fixed != null) return fixed;
    return escalate
        ? rateLimitCooldownFor(widget.scope)
        : _backoff(_recordFailure(widget.scope, escalate: false));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown(Duration cooldown) {
    _timer?.cancel();
    _remaining = cooldown;
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
              if (widget.rateLimited) {
                // 只挡住下一次点击，不额外记一次连击：真正的连击由重试后的
                // 结果决定。
                setState(
                  () => _startCooldown(_resolveCooldown(escalate: false)),
                );
              }
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
  final String scope = 'default',
  final Duration? cooldown,
  final ButtonStyle? style,

  /// 这次失败本身，换了对象就放大冷却。
  final Object? failure,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => RetryCooldownBuilder(
    rateLimited: rateLimited,
    onRetry: onRetry,
    scope: scope,
    cooldown: cooldown,
    failure: failure,
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
  final String scope = 'default',
  final Duration? cooldown,

  /// 这次失败本身，换了对象就放大冷却。
  final Object? failure,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => RetryCooldownBuilder(
    rateLimited: rateLimited,
    onRetry: onRetry,
    scope: scope,
    cooldown: cooldown,
    failure: failure,
    builder: (context, countdown, coolingDown, onPressed) => TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(AppIcons.refresh, size: 18),
      label: Text(coolingDown ? countdown : label),
    ),
  );
}
