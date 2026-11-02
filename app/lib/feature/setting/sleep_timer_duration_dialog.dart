import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Dialog for entering a validated sleep-timer duration.
class const SleepTimerDurationDialog({
  required final String title,
  required final String minutesLabel,
  required final String invalidDurationMessage,
  required final String cancelLabel,
  required final String confirmLabel,
  required final int minMinutes,
  required final int maxMinutes,
  super.key,
}) extends StatefulWidget {
  @override
  State<SleepTimerDurationDialog> createState() =>
      _SleepTimerDurationDialogState();
}

class _SleepTimerDurationDialogState() extends State<SleepTimerDurationDialog> {
  late final TextEditingController _input;
  String? _error;

  @override
  void initState() {
    super.initState();
    _input = TextEditingController();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(_input.text.trim());
    if (value == null ||
        value < widget.minMinutes ||
        value > widget.maxMinutes) {
      setState(() => _error = widget.invalidDurationMessage);
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      controller: _input,
      autofocus: true,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: widget.minutesLabel,
        errorText: _error,
      ),
      onSubmitted: (_) => _submit(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(widget.cancelLabel),
      ),
      FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
    ],
  );
}
