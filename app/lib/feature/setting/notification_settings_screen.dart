import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';

import '../../datastore/preferences_data_source.dart';
import '../../l10n/localization_file/app_localizations.dart';
import '../../main.dart';
import '../notification/feed_update_notifier.dart';

class const NotificationSettingsScreen({super.key}) extends StatefulWidget {
  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState()
    extends State<NotificationSettingsScreen> {
  bool _feedUpdateEnabled = true;
  int _threshold = 3;
  PreferencesDataSource? _preferences;
  FeedUpdateNotifier? _notifier;
  bool _loading = true;

  static const _thresholdOptions = [0, 1, 3, 5, 10];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    PreferencesDataSource? preferences;
    FeedUpdateNotifier? notifier;
    try {
      preferences = context.read<PreferencesDataSource>();
    } on Object catch (_) {
      // Keep the subpage usable in isolated widget tests without the
      // application-level repository providers.
    }
    try {
      notifier = context.read<FeedUpdateNotifier>();
    } on Object catch (_) {
      // No notifier registered (tests, unsupported builds): the toggle still
      // persists the preference.
    }

    if (preferences == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final thresholdResult = await preferences.get(
      PreferencesKey.feedUpdateNotificationThreshold,
    );

    if (!mounted) return;
    setState(() {
      _preferences = preferences;
      _notifier = notifier;
      _threshold = thresholdResult is Success<int, Exception>
          ? thresholdResult.success
          : 3;
      _feedUpdateEnabled = _threshold > 0;
      _loading = false;
    });
  }

  Future<void> _updateEnabled(bool enabled) async {
    unawaited(HapticFeedback.selectionClick());
    final nextThreshold = enabled ? (_threshold > 0 ? _threshold : 3) : 0;
    setState(() {
      _feedUpdateEnabled = enabled;
      _threshold = nextThreshold;
    });
    final preferences = _preferences;
    if (preferences != null) {
      await preferences.set(
        PreferencesKey.feedUpdateNotificationThreshold,
        nextThreshold,
      );
    }
    if (!enabled) return;

    // Turning the feature on is where a system permission dialog is expected.
    final notifier = _notifier;
    if (notifier == null || !notifier.isSupported) return;
    await notifier.initialize();
    final granted = await notifier.requestPermission();
    if (!mounted) return;
    if (granted case Success(:final success) when !success) {
      setState(() {
        _feedUpdateEnabled = false;
        _threshold = 0;
      });
      await preferences?.set(PreferencesKey.feedUpdateNotificationThreshold, 0);
    }
  }

  Future<void> _updateThreshold(int threshold) async {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _threshold = threshold;
      _feedUpdateEnabled = threshold > 0;
    });
    final preferences = _preferences;
    if (preferences != null) {
      await preferences.set(
        PreferencesKey.feedUpdateNotificationThreshold,
        threshold,
      );
    }
  }

  String _thresholdLabel(int threshold, AppLocalizations l10n) {
    if (threshold <= 0) return l10n.feedUpdateThresholdOff;
    return l10n.feedUpdateThresholdOption(threshold);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsNotifications)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.symmetric(vertical: $styles.insets.xs),
              children: [
                _sectionHeader(l10n.settingsNotifications),
                SwitchListTile(
                  title: Text(l10n.feedUpdateNotifications),
                  subtitle: Text(l10n.feedUpdateNotificationsSubtitle),
                  value: _feedUpdateEnabled,
                  onChanged: (enabled) {
                    unawaited(_updateEnabled(enabled));
                  },
                ),
                if (_feedUpdateEnabled) ...[
                  _sectionHeader(l10n.feedUpdateThreshold),
                  ListTile(
                    title: Text(l10n.feedUpdateThreshold),
                    subtitle: Text(l10n.feedUpdateThresholdSubtitle),
                    trailing: DropdownButton<int>(
                      value: _threshold,
                      onChanged: (value) {
                        if (value != null) {
                          unawaited(_updateThreshold(value));
                        }
                      },
                      items: _thresholdOptions.map((threshold) {
                        return DropdownMenuItem<int>(
                          value: threshold,
                          child: Text(_thresholdLabel(threshold, l10n)),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
    padding: EdgeInsets.only(
      left: $styles.insets.md,
      top: $styles.insets.sm,
      bottom: $styles.insets.xs,
    ),
    child: Text(
      title,
      style: $styles.text.bodySmall.copyWith(
        color: $styles.colors.onSurfaceVariant,
      ),
    ),
  );
}
