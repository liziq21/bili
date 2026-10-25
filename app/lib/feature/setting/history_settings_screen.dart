import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../datastore/media_history_settings.dart';
import '../../datastore/preferences_data_source.dart';
import '../../l10n/localization_file/app_localizations.dart';
import '../../main.dart';

class const HistorySettingsScreen({super.key}) extends StatefulWidget {
  @override
  State<HistorySettingsScreen> createState() => _HistorySettingsScreenState();
}

class _HistorySettingsScreenState() extends State<HistorySettingsScreen> {
  MediaHistorySettings _settings = const MediaHistorySettings();
  PreferencesDataSource? _preferences;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    PreferencesDataSource? preferences;
    try {
      preferences = context.read<PreferencesDataSource>();
    } on Object catch (_) {
      // Keep the skeleton subpage usable in isolated widget tests without the
      // application-level repository providers.
    }

    if (preferences == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final settings = await MediaHistorySettings.load(preferences);
    if (!mounted) return;
    setState(() {
      _preferences = preferences;
      _settings = settings;
      _loading = false;
    });
  }

  Future<void> _update(MediaHistorySettings settings) async {
    setState(() => _settings = settings);
    final preferences = _preferences;
    if (preferences != null) await settings.save(preferences);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsHistory)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.symmetric(vertical: $styles.insets.xs),
              children: [
                SwitchListTile(
                  title: Text(l10n.historyRecording),
                  subtitle: Text(l10n.historyRecordingSubtitle),
                  value: _settings.recordHistory,
                  onChanged: (enabled) {
                    HapticFeedback.selectionClick();
                    _update(_settings.copyWith(recordHistory: enabled));
                  },
                ),
                SwitchListTile(
                  title: Text(l10n.historyResumePlayback),
                  subtitle: Text(l10n.historyResumePlaybackSubtitle),
                  value: _settings.resumePlayback,
                  onChanged: (enabled) {
                    HapticFeedback.selectionClick();
                    _update(_settings.copyWith(resumePlayback: enabled));
                  },
                ),
              ],
            ),
    );
  }
}
