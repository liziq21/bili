import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../datastore/preferences_data_source.dart';
import '../../domain/sleep_timer_action.dart';
import '../../l10n/localization_file/app_localizations.dart';
import '../../main.dart';
import 'app_settings.dart';
import 'common_widgets/setting_tiles.dart';
import 'sleep_timer_duration_dialog.dart';

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

  /// 写入队列：并发保存可能乱序完成，让旧快照覆盖用户刚选的新值。
  Future<void> _saveQueue = Future<void>.value();

  Future<void> _enqueueSave(Future<void> Function() save) {
    final next = _saveQueue.then((_) => save());
    // 一次失败不该让后续保存全部短路；失败在这里报告一次，调用方无需处理。
    _saveQueue = next.catchError((Object error, StackTrace stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'player settings',
        ),
      );
    });
    return _saveQueue;
  }

  Future<void> _updatePlayer(PlayerSettings settings) {
    setState(() => _playerSettings = settings);
    final preferences = _preferences;
    if (preferences == null) return Future<void>.value();
    return _enqueueSave(() => settings.save(preferences));
  }

  Future<void> _updateGestures(GestureSettings settings) {
    setState(() => _gestureSettings = settings);
    final preferences = _preferences;
    if (preferences == null) return Future<void>.value();
    return _enqueueSave(() => settings.save(preferences));
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
                SettingValueTile(
                  title: l10n.playerDefaultQuality,
                  subtitle: l10n.playerDefaultQualitySubtitle,
                  value: _qualityLabel(
                    l10n,
                    _playerSettings.preferredQualityHeight,
                  ),
                  onTap: () => _showQualityPicker(context),
                ),
                SettingValueTile(
                  title: l10n.playerDefaultSpeed,
                  subtitle: l10n.playerDefaultSpeedSubtitle,
                  value: playbackRateLabel(_playerSettings.playbackRate),
                  onTap: () => _showSpeedPicker(context),
                ),
                SettingSectionHeader(title: l10n.playerGestures),
                SettingSwitchTile(
                  title: l10n.playerGestureSeek,
                  subtitle: l10n.playerGestureSeekSubtitle,
                  value: _gestureSettings.seekEnabled,
                  onChanged: (enabled) => _updateGestures(
                    _gestureSettings.copyWith(seekEnabled: enabled),
                  ),
                ),
                SettingSwitchTile(
                  title: l10n.playerGestureVolume,
                  subtitle: l10n.playerGestureVolumeSubtitle,
                  value: _gestureSettings.volumeEnabled,
                  onChanged: (enabled) => _updateGestures(
                    _gestureSettings.copyWith(volumeEnabled: enabled),
                  ),
                ),
                SettingSwitchTile(
                  title: l10n.playerGestureBrightness,
                  subtitle: l10n.playerGestureBrightnessSubtitle,
                  value: _gestureSettings.brightnessEnabled,
                  onChanged: (enabled) => _updateGestures(
                    _gestureSettings.copyWith(brightnessEnabled: enabled),
                  ),
                ),
                SettingSwitchTile(
                  title: l10n.playerGestureBoost,
                  subtitle: l10n.playerGestureBoostSubtitle,
                  value: _gestureSettings.boostEnabled,
                  onChanged: (enabled) => _updateGestures(
                    _gestureSettings.copyWith(boostEnabled: enabled),
                  ),
                ),
                SettingValueTile(
                  title: l10n.playerSleepTimerDefault,
                  subtitle: l10n.playerSleepTimerDefaultSubtitle,
                  value: _sleepTimerLabel(l10n),
                  onTap: () => _showSleepTimerPicker(context),
                ),
                SettingValueTile(
                  title: l10n.playerSleepTimerAction,
                  subtitle: l10n.playerSleepTimerActionSubtitle,
                  value: _sleepTimerActionLabel(
                    l10n,
                    _playerSettings.sleepTimerDefaultAction,
                  ),
                  onTap: () => _showSleepTimerActionPicker(context),
                ),
              ],
            ),
    );
  }

  String _qualityLabel(AppLocalizations l10n, int? height) => height == null
      ? l10n.playerQualityAuto
      : l10n.playerQualityHeight('$height');

  String _sleepTimerLabel(AppLocalizations l10n) {
    final minutes = _playerSettings.sleepTimerDefaultMinutes;
    if (minutes == 0) return l10n.playerSleepTimerOff;
    return l10n.minutesValue('$minutes');
  }

  String _sleepTimerActionLabel(
    AppLocalizations l10n,
    SleepTimerAction action,
  ) => switch (action) {
    SleepTimerAction.pauseNow => l10n.sleepTimerActionNowLabel,
    SleepTimerAction.afterCurrent => l10n.sleepTimerAfterCurrentTitle,
    SleepTimerAction.exitPlayer => l10n.sleepTimerActionExitPlayerLabel,
  };

  void _showSleepTimerActionPicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            SettingPickerTitle(title: l10n.playerSleepTimerAction),
            for (final action in SleepTimerAction.values)
              SettingPickerOption(
                title: _sleepTimerActionLabel(l10n, action),
                selected: action == _playerSettings.sleepTimerDefaultAction,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _updatePlayer(
                    _playerSettings.copyWith(sleepTimerDefaultAction: action),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showQualityPicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            SettingPickerTitle(title: l10n.playerDefaultQuality),
            for (final height in kPreferredQualityHeights)
              SettingPickerOption(
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
            SettingPickerTitle(title: l10n.playerDefaultSpeed),
            for (final rate in kPlaybackRates)
              SettingPickerOption(
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
            SettingPickerTitle(title: l10n.playerSleepTimerDefault),
            SettingPickerOption(
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
              SettingPickerOption(
                title: l10n.minutesValue('$minutes'),
                selected: minutes == _playerSettings.sleepTimerDefaultMinutes,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _updatePlayer(
                    _playerSettings.copyWith(sleepTimerDefaultMinutes: minutes),
                  );
                },
              ),
            SettingPickerOption(
              title: _customSleepTimerLabel(l10n),
              selected: _isCustomSleepTimer,
              onTap: () async {
                final minutes = await _showCustomSleepTimerDialog(sheetContext);
                if (!mounted || !sheetContext.mounted || minutes == null) {
                  return;
                }
                Navigator.of(sheetContext).pop();
                await _updatePlayer(
                  _playerSettings.copyWith(sleepTimerDefaultMinutes: minutes),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  bool get _isCustomSleepTimer {
    final minutes = _playerSettings.sleepTimerDefaultMinutes;
    return minutes > 0 && !kSleepTimerMinutes.contains(minutes);
  }

  String _customSleepTimerLabel(AppLocalizations l10n) {
    final minutes = _playerSettings.sleepTimerDefaultMinutes;
    return _isCustomSleepTimer
        ? l10n.sleepTimerCustomValue('$minutes')
        : l10n.sleepTimerCustom;
  }

  Future<int?> _showCustomSleepTimerDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<int>(
      context: context,
      builder: (_) => SleepTimerDurationDialog(
        title: l10n.sleepTimerCustomTitle,
        minutesLabel: l10n.sleepTimerMinutesHint,
        invalidDurationMessage: l10n.sleepTimerInvalidDuration,
        cancelLabel: l10n.dialogCancel,
        confirmLabel: l10n.confirm,
        minMinutes: kMinSleepTimerMinutes,
        maxMinutes: kMaxSleepTimerMinutes,
      ),
    );
  }
}
