import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../datastore/preferences_data_source.dart';
import '../../l10n/localization_file/app_localizations.dart';
import '../../main.dart';
import 'app_settings.dart';

class const PlayerSettingsScreen({super.key}) extends StatefulWidget {
  @override
  State<PlayerSettingsScreen> createState() => _PlayerSettingsScreenState();
}

class _PlayerSettingsScreenState() extends State<PlayerSettingsScreen> {
  PlayerSettings _playerSettings = const PlayerSettings();
  GestureSettings _gestureSettings = const GestureSettings();
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
      // Keep the page usable in isolated widget tests without app providers.
    }

    if (preferences == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final playerSettings = await PlayerSettings.load(preferences);
    final gestureSettings = await GestureSettings.load(preferences);
    if (!mounted) return;
    setState(() {
      _preferences = preferences;
      _playerSettings = playerSettings;
      _gestureSettings = gestureSettings;
      _loading = false;
    });
  }

  Future<void> _updatePlayer(PlayerSettings settings) async {
    setState(() => _playerSettings = settings);
    final preferences = _preferences;
    if (preferences != null) await settings.save(preferences);
  }

  Future<void> _updateGestures(GestureSettings settings) async {
    setState(() => _gestureSettings = settings);
    final preferences = _preferences;
    if (preferences != null) await settings.save(preferences);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsPlayer)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.symmetric(vertical: $styles.insets.xs),
              children: [
                _valueTile(
                  title: l10n.playerDefaultQuality,
                  subtitle: l10n.playerDefaultQualitySubtitle,
                  value: _qualityLabel(
                    l10n,
                    _playerSettings.preferredQualityHeight,
                  ),
                  onTap: () => _showQualityPicker(context),
                ),
                _valueTile(
                  title: l10n.playerDefaultSpeed,
                  subtitle: l10n.playerDefaultSpeedSubtitle,
                  value: playbackRateLabel(_playerSettings.playbackRate),
                  onTap: () => _showSpeedPicker(context),
                ),
                _sectionHeader(l10n.playerGestures),
                SwitchListTile(
                  title: Text(l10n.playerGestureSeek),
                  subtitle: Text(l10n.playerGestureSeekSubtitle),
                  value: _gestureSettings.seekEnabled,
                  onChanged: (enabled) => _updateGestures(
                    _gestureSettings.copyWith(seekEnabled: enabled),
                  ),
                ),
                SwitchListTile(
                  title: Text(l10n.playerGestureVolume),
                  subtitle: Text(l10n.playerGestureVolumeSubtitle),
                  value: _gestureSettings.volumeEnabled,
                  onChanged: (enabled) => _updateGestures(
                    _gestureSettings.copyWith(volumeEnabled: enabled),
                  ),
                ),
                SwitchListTile(
                  title: Text(l10n.playerGestureBrightness),
                  subtitle: Text(l10n.playerGestureBrightnessSubtitle),
                  value: _gestureSettings.brightnessEnabled,
                  onChanged: (enabled) => _updateGestures(
                    _gestureSettings.copyWith(brightnessEnabled: enabled),
                  ),
                ),
                SwitchListTile(
                  title: Text(l10n.playerGestureBoost),
                  subtitle: Text(l10n.playerGestureBoostSubtitle),
                  value: _gestureSettings.boostEnabled,
                  onChanged: (enabled) => _updateGestures(
                    _gestureSettings.copyWith(boostEnabled: enabled),
                  ),
                ),
                _valueTile(
                  title: l10n.playerSleepTimerDefault,
                  subtitle: l10n.playerSleepTimerDefaultSubtitle,
                  value: _sleepTimerLabel(l10n),
                  onTap: () => _showSleepTimerPicker(context),
                ),
              ],
            ),
    );
  }

  Widget _valueTile({
    required String title,
    required String subtitle,
    required String value,
    required VoidCallback onTap,
  }) => ListTile(
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: $styles.text.bodySmall.copyWith(
            color: $styles.colors.onSurfaceVariant,
          ),
        ),
        Icon(Icons.chevron_right, color: $styles.colors.onSurfaceVariant),
      ],
    ),
    onTap: onTap,
  );

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

  String _qualityLabel(AppLocalizations l10n, int? height) => height == null
      ? l10n.playerQualityAuto
      : l10n.playerQualityHeight('$height');

  String _sleepTimerLabel(AppLocalizations l10n) {
    final minutes = _playerSettings.sleepTimerDefaultMinutes;
    if (minutes == 0) return l10n.playerSleepTimerOff;
    return l10n.minutesValue('$minutes');
  }

  void _showQualityPicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            _pickerTitle(l10n.playerDefaultQuality),
            for (final height in kPreferredQualityHeights)
              _pickerOption(
                title: _qualityLabel(l10n, height),
                selected: height == _playerSettings.preferredQualityHeight,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _updatePlayer(
                    _playerSettings.copyWith(
                      preferredQualityHeight: height,
                      preferredQualityStreamId: null,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showSpeedPicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            _pickerTitle(l10n.playerDefaultSpeed),
            for (final rate in kPlaybackRates)
              _pickerOption(
                title: playbackRateLabel(rate),
                selected: rate == _playerSettings.playbackRate,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _updatePlayer(_playerSettings.copyWith(playbackRate: rate));
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showSleepTimerPicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            _pickerTitle(l10n.playerSleepTimerDefault),
            _pickerOption(
              title: l10n.playerSleepTimerOff,
              selected: _playerSettings.sleepTimerDefaultMinutes == 0,
              onTap: () {
                Navigator.of(sheetContext).pop();
                _updatePlayer(
                  _playerSettings.copyWith(sleepTimerDefaultMinutes: 0),
                );
              },
            ),
            for (final minutes in kSleepTimerMinutes)
              _pickerOption(
                title: l10n.minutesValue('$minutes'),
                selected: minutes == _playerSettings.sleepTimerDefaultMinutes,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _updatePlayer(
                    _playerSettings.copyWith(sleepTimerDefaultMinutes: minutes),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _pickerTitle(String title) => Padding(
    padding: EdgeInsets.symmetric(vertical: $styles.insets.sm),
    child: Text(title, style: $styles.text.bodySmallBold),
  );

  Widget _pickerOption({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) => ListTile(
    title: Text(title),
    trailing: selected
        ? Icon(Icons.check, color: $styles.colors.accentText)
        : null,
    onTap: onTap,
  );
}
