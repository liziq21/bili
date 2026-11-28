import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';

import '../../datastore/preferences_data_source.dart';
import '../../l10n/localization_file/app_localizations.dart';
import '../../main.dart';
import 'common_widgets/setting_tiles.dart';

class const LibrarySettingsScreen({super.key}) extends StatefulWidget {
  @override
  State<LibrarySettingsScreen> createState() => _LibrarySettingsScreenState();
}

class _LibrarySettingsScreenState() extends State<LibrarySettingsScreen> {
  int _searchHistoryRetentionDays = 30;
  PreferencesDataSource? _preferences;
  bool _loading = true;

  static const _retentionOptions = [7, 30, 90, -1];

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

    final searchHistoryResult = await preferences.get(
      PreferencesKey.searchHistoryRetentionDays,
    );

    if (!mounted) return;
    setState(() {
      _preferences = preferences;
      _searchHistoryRetentionDays =
          searchHistoryResult is Success<int, Exception>
          ? searchHistoryResult.success
          : 30;
      _loading = false;
    });
  }

  Future<void> _updateSearchHistoryRetention(int days) async {
    setState(() => _searchHistoryRetentionDays = days);
    final preferences = _preferences;
    if (preferences != null) {
      await preferences.set(PreferencesKey.searchHistoryRetentionDays, days);
    }
  }

  String _retentionLabel(int days, AppLocalizations l10n) {
    switch (days) {
      case 7:
        return l10n.librarySearchHistoryRetention7Days;
      case 30:
        return l10n.librarySearchHistoryRetention30Days;
      case 90:
        return l10n.librarySearchHistoryRetention90Days;
      case -1:
        return l10n.librarySearchHistoryRetentionForever;
      default:
        return l10n.librarySearchHistoryRetention30Days;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final retentionText = _retentionLabel(_searchHistoryRetentionDays, l10n);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsLibrary)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.symmetric(vertical: $styles.insets.xs),
              children: [
                SettingValueTile(
                  title: l10n.librarySearchHistoryRetention,
                  subtitle: l10n.librarySearchHistoryRetentionSubtitle,
                  value: retentionText,
                  onTap: () => unawaited(
                    showSettingPicker<int>(
                      context: context,
                      title: l10n.librarySearchHistoryRetention,
                      selected: _searchHistoryRetentionDays,
                      choices: [
                        for (final days in _retentionOptions)
                          SettingPickerChoice(
                            days,
                            _retentionLabel(days, l10n),
                          ),
                      ],
                      onSelected: (days) =>
                          unawaited(_updateSearchHistoryRetention(days)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
