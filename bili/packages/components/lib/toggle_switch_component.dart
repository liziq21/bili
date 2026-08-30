// https://github.com/ente/ente/blob/main/mobile/packages/ente_components/lib/components/selection_controls/toggle_switch_component.dart

import 'dart:async';

import 'package:flutter/material.dart';

import 'theme/motion.dart';

class ToggleSwitchComponent extends StatefulWidget {
  const ToggleSwitchComponent({
    super.key,
    required this.selected,
    required this.onChanged,
    this.showStateIcon = false,
    this.loadingDelay = _defaultLoadingDelay,
    this.minimumFeedbackDuration = _defaultFeedbackDuration,
    this.successDuration = _defaultSuccessDuration,
  }) : _value = null;

  ToggleSwitchComponent.async({
    super.key,
    required ValueGetter<bool> value,
    required FutureOr<void> Function() onChanged,
    this.showStateIcon = true,
    this.loadingDelay = _defaultLoadingDelay,
    this.minimumFeedbackDuration = _defaultFeedbackDuration,
    this.successDuration = _defaultSuccessDuration,
  }) : selected = value(),
       _value = value,
       onChanged = ((_) => onChanged());

  static const _defaultLoadingDelay = Duration(milliseconds: 300);
  static const _defaultFeedbackDuration = Duration(milliseconds: 200);
  static const _defaultSuccessDuration = Duration(seconds: 2);

  final bool selected;
  final FutureOr<void> Function(bool selected)? onChanged;
  final bool showStateIcon;
  final Duration loadingDelay;
  final Duration minimumFeedbackDuration;
  final Duration successDuration;
  final ValueGetter<bool>? _value;

  @override
  State<ToggleSwitchComponent> createState() => _ToggleSwitchComponentState();
}

class _ToggleSwitchComponentState extends State<ToggleSwitchComponent> {
  bool? _selected;
  _ToggleSwitchExecutionState _executionState =
      _ToggleSwitchExecutionState.idle;
  Timer? _loadingTimer;
  Timer? _successTimer;
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = widget.onChanged != null && !_isUpdating;
    final selected = _selected ?? widget.selected;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showStateIcon) ...[
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: AnimatedSwitcher(
              duration: Motion.standard,
              switchInCurve: Curves.easeInExpo,
              switchOutCurve: Curves.easeOutExpo,
              child: ExcludeSemantics(child: _stateIcon(theme)),
            ),
          ),
        ],
        SizedBox(
          height: 31,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Switch(
              inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
              activeTrackColor: theme.colorScheme.primary,
              activeThumbColor: theme.colorScheme.onPrimary,
              inactiveThumbColor: theme.colorScheme.outline,
              trackOutlineColor: WidgetStateColor.resolveWith(
                (states) => enabled
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              value: selected,
              onChanged: enabled ? _handleChanged : null,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void didUpdateWidget(covariant ToggleSwitchComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newValue = _currentValue();
    if (_selected != newValue && !_isUpdating) {
      _selected = newValue;
    }
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _successTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _selected = _currentValue();
  }

  bool _currentValue() => widget._value?.call() ?? widget.selected;

  Future<void> _handleChanged(bool nextValue) async {
    if (!mounted || widget.onChanged == null) {
      return;
    }

    _loadingTimer?.cancel();
    _successTimer?.cancel();
    setState(() {
      _isUpdating = true;
      _selected = nextValue;
      _executionState = _ToggleSwitchExecutionState.idle;
    });

    _loadingTimer = Timer(widget.loadingDelay, () {
      if (!mounted) {
        return;
      }
      setState(() {
        _executionState = _ToggleSwitchExecutionState.inProgress;
      });
    });

    final stopwatch = Stopwatch()..start();
    try {
      await widget.onChanged!(nextValue);
    } catch (_) {
      await _waitForMinimumFeedback(stopwatch);
      _loadingTimer?.cancel();
      if (!mounted) {
        return;
      }
      setState(() {
        _selected = _currentValue();
        _executionState = _ToggleSwitchExecutionState.idle;
        _isUpdating = false;
      });
      return;
    }

    await _waitForMinimumFeedback(stopwatch);
    _loadingTimer?.cancel();
    if (!mounted) {
      return;
    }

    final confirmedValue = _currentValue();
    setState(() {
      if (_selected == confirmedValue) {
        if (_executionState == _ToggleSwitchExecutionState.inProgress) {
          _executionState = _ToggleSwitchExecutionState.successful;
          _successTimer = Timer(widget.successDuration, () {
            if (!mounted) {
              return;
            }
            setState(() {
              _executionState = _ToggleSwitchExecutionState.idle;
            });
          });
        } else {
          _executionState = _ToggleSwitchExecutionState.idle;
        }
      } else {
        _selected = confirmedValue;
        _executionState = _ToggleSwitchExecutionState.idle;
      }
      _isUpdating = false;
    });
  }

  Widget _stateIcon(ThemeData theme) {
    return switch (_executionState) {
      _ToggleSwitchExecutionState.idle => const SizedBox(
        key: ValueKey('toggle-state-idle'),
        width: 24,
      ),
      _ToggleSwitchExecutionState.inProgress => SizedBox.square(
        key: const ValueKey('toggle-state-loading'),
        dimension: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: theme.colorScheme.outline,
        ),
      ),
      _ToggleSwitchExecutionState.successful => Padding(
        key: const ValueKey('toggle-state-success'),
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: Icon(
          Icons.check_outlined,
          size: 22,
          color: theme.colorScheme.primary,
        ),
      ),
    };
  }

  Future<void> _waitForMinimumFeedback(Stopwatch stopwatch) async {
    final remaining =
        widget.minimumFeedbackDuration -
        Duration(milliseconds: stopwatch.elapsedMilliseconds);
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
  }
}

enum _ToggleSwitchExecutionState { idle, inProgress, successful }
