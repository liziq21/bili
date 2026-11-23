import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../datastore/preferences_data_source.dart';
import '../../l10n/localization_file/app_localizations.dart';
import '../../main.dart';
import 'app_settings.dart';

/// Channel-page tab visibility settings.
///
/// Only tabs the channel page can actually render are listed; adding a new tab
/// means adding its id to [ChannelTabs] and a switch here.
class const ChannelSettingsScreen({super.key}) extends StatefulWidget {
  @override
  State<ChannelSettingsScreen> createState() => _ChannelSettingsScreenState();
}

class _ChannelSettingsScreenState() extends State<ChannelSettingsScreen> {
  ChannelTabSettings _settings = const ChannelTabSettings();
  PreferencesDataSource? _preferences;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final preferences = context.read<PreferencesDataSource?>();
    if (preferences == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final settings = await ChannelTabSettings.load(preferences);
    if (!mounted) return;
    setState(() {
      _preferences = preferences;
      _settings = settings;
      _loading = false;
    });
  }

  Future<void> _setTabVisible(String tabId, bool visible) async {
    unawaited(HapticFeedback.selectionClick());
    final updated = _settings.withTabVisible(tabId, visible);
    setState(() => _settings = updated);
    final preferences = _preferences;
    if (preferences != null) await updated.save(preferences);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final videosVisible = _settings.isVisible(ChannelTabs.videos);
    final playlistsVisible = _settings.isVisible(ChannelTabs.playlists);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsChannel)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.symmetric(vertical: $styles.insets.xs),
              children: [
                Tooltip(
                  message:
                      '${l10n.videoTab}: ${videosVisible ? l10n.homeConfigVisible : l10n.homeConfigHidden}',
                  child: SwitchListTile(
                    title: Text(l10n.videoTab),
                    value: videosVisible,
                    onChanged: (value) {
                      unawaited(_setTabVisible(ChannelTabs.videos, value));
                    },
                  ),
                ),
                Tooltip(
                  message:
                      '${l10n.channelTabPlaylists}: ${playlistsVisible ? l10n.homeConfigVisible : l10n.homeConfigHidden}',
                  child: SwitchListTile(
                    title: Text(l10n.channelTabPlaylists),
                    value: playlistsVisible,
                    onChanged: (value) {
                      unawaited(_setTabVisible(ChannelTabs.playlists, value));
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
