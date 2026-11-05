import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';

import '../../datastore/preferences_data_source.dart';
import '../../l10n/localization_file/app_localizations.dart';
import '../../main.dart';

class const LibrarySettingsScreen({super.key}) extends StatefulWidget {
  @override
  State<LibrarySettingsScreen> createState() => _LibrarySettingsScreenState();
}

class _LibrarySettingsScreenState() extends State<LibrarySettingsScreen> {
  bool _bookmarkSyncEnabled = true;
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

    final bookmarkSyncResult = await preferences.get(
      PreferencesKey.bookmarkSyncEnabled,
    );
    final searchHistoryResult = await preferences.get(
      PreferencesKey.searchHistoryRetentionDays,
    );

    if (!mounted) return;
    setState(() {
      _preferences = preferences;
      _bookmarkSyncEnabled = bookmarkSyncResult is Success<bool, Exception>
          ? bookmarkSyncResult.success
          : true;
      _searchHistoryRetentionDays =
          searchHistoryResult is Success<int, Exception>
          ? searchHistoryResult.success
          : 30;
      _loading = false;
    });
  }

  Future<void> _updateBookmarkSync(bool enabled) async {
    HapticFeedback.selectionClick();
    setState(() => _bookmarkSyncEnabled = enabled);
    final preferences = _preferences;
    if (preferences != null) {
      await preferences.set(PreferencesKey.bookmarkSyncEnabled, enabled);
    }
  }

  Future<void> _updateSearchHistoryRetention(int days) async {
    HapticFeedback.selectionClick();
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
                _sectionHeader(l10n.libraryBookmarkSync),
                Tooltip(
                  message:
                      '${l10n.libraryBookmarkSync}: ${_bookmarkSyncEnabled ? l10n.confirm : l10n.dialogCancel}',
                  child: SwitchListTile(
                    title: Text(l10n.libraryBookmarkSync),
                    subtitle: Text(l10n.libraryBookmarkSyncSubtitle),
                    value: _bookmarkSyncEnabled,
                    onChanged: (enabled) {
                      unawaited(_updateBookmarkSync(enabled));
                    },
                  ),
                ),
                _sectionHeader(l10n.librarySearchHistoryRetention),
                Tooltip(
                  message:
                      '${l10n.librarySearchHistoryRetention}: $retentionText',
                  child: ListTile(
                    title: Text(l10n.librarySearchHistoryRetention),
                    subtitle: Text(l10n.librarySearchHistoryRetentionSubtitle),
                    trailing: Semantics(
                      label: l10n.librarySearchHistoryRetention,
                      value: retentionText,
                      excludeSemantics: true,
                      child: DropdownButton<int>(
                        value: _searchHistoryRetentionDays,
                        onChanged: (value) {
                          if (value != null) {
                            unawaited(_updateSearchHistoryRetention(value));
                          }
                        },
                        items: _retentionOptions.map((days) {
                          return DropdownMenuItem<int>(
                            value: days,
                            child: Text(_retentionLabel(days, l10n)),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
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
