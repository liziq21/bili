import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../datastore/preferences_data_source.dart';
import '../../../l10n/localization_file/app_localizations.dart';
import '../../../main.dart';
import 'danmaku_settings.dart';

/// Danmaku controls are kept in a standalone page so the same preferences can
/// be used by the player overlay and a future general settings index.
class const DanmakuSettingsScreen({super.key}) extends StatefulWidget {
  @override
  State<DanmakuSettingsScreen> createState() => _DanmakuSettingsScreenState();
}

class _DanmakuSettingsScreenState() extends State<DanmakuSettingsScreen> {
  DanmakuSettings _settings = const DanmakuSettings();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await DanmakuSettings.load(
      context.read<PreferencesDataSource>(),
    );
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _loading = false;
    });
  }

  Future<void> _update(DanmakuSettings settings) async {
    setState(() => _settings = settings);
    await settings.save(context.read<PreferencesDataSource>());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.danmakuSettingsTitle ?? 'Danmaku settings'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.symmetric(vertical: $styles.insets.xs),
              children: [
                SwitchListTile(
                  title: Text(l10n?.showDanmaku ?? 'Show danmaku'),
                  subtitle: Text(
                    l10n?.showTimelineDanmakuOnVideo ??
                        'Show timeline danmaku on video',
                  ),
                  value: _settings.enabled,
                  onChanged: (enabled) =>
                      _update(_settings.copyWith(enabled: enabled)),
                ),
                _SliderSetting(
                  title:
                      l10n?.regularDanmakuDuration ??
                      'Scrolling danmaku duration',
                  value: _settings.regularDuration,
                  min: 4,
                  max: 16,
                  divisions: 12,
                  valueLabel:
                      l10n?.secondsValue(
                        _settings.regularDuration.toStringAsFixed(1),
                      ) ??
                      '',
                  onChanged: (value) =>
                      _update(_settings.copyWith(regularDuration: value)),
                ),
                _SliderSetting(
                  title:
                      l10n?.topBottomDanmakuDuration ??
                      'Top/bottom danmaku duration',
                  value: _settings.topBottomDuration,
                  min: 3,
                  max: 12,
                  divisions: 9,
                  valueLabel:
                      l10n?.secondsValueTopBottom(
                        _settings.topBottomDuration.toStringAsFixed(1),
                      ) ??
                      '',
                  onChanged: (value) =>
                      _update(_settings.copyWith(topBottomDuration: value)),
                ),
                _SliderSetting(
                  title: l10n?.opacity ?? 'Opacity',
                  value: _settings.opacity,
                  min: .2,
                  max: 1,
                  divisions: 8,
                  valueLabel: '${(_settings.opacity * 100).round()}%',
                  onChanged: (value) =>
                      _update(_settings.copyWith(opacity: value)),
                ),
                _SliderSetting(
                  title: l10n?.fontSize ?? 'Font size',
                  value: _settings.fontSize,
                  min: 12,
                  max: 32,
                  divisions: 20,
                  valueLabel: '${_settings.fontSize.round()} px',
                  onChanged: (value) =>
                      _update(_settings.copyWith(fontSize: value)),
                ),
                _SliderSetting(
                  title: l10n?.strokeRadius ?? 'Stroke radius',
                  value: _settings.outlineRadius,
                  min: 0,
                  max: 5,
                  divisions: 10,
                  valueLabel: _settings.outlineRadius.toStringAsFixed(1),
                  onChanged: (value) =>
                      _update(_settings.copyWith(outlineRadius: value)),
                ),
                _SliderSetting(
                  title: l10n?.topMaxRows ?? 'Top max rows',
                  value: _settings.topMaxRows.toDouble(),
                  min: 1,
                  max: 6,
                  divisions: 5,
                  valueLabel:
                      l10n?.topRowsValue('${_settings.topMaxRows}') ?? '',
                  onChanged: (value) =>
                      _update(_settings.copyWith(topMaxRows: value.round())),
                ),
                _SliderSetting(
                  title: l10n?.bottomMaxRows ?? 'Bottom max rows',
                  value: _settings.bottomMaxRows.toDouble(),
                  min: 1,
                  max: 6,
                  divisions: 5,
                  valueLabel:
                      l10n?.bottomRowsValue('${_settings.bottomMaxRows}') ?? '',
                  onChanged: (value) =>
                      _update(_settings.copyWith(bottomMaxRows: value.round())),
                ),
              ],
            ),
    );
  }
}

class const _SliderSetting({
  required final String title,
  required final double value,
  required final double min,
  required final double max,
  required final int divisions,
  required final String valueLabel,
  required final ValueChanged<double> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Slider(
        value: value.clamp(min, max).toDouble(),
        min: min,
        max: max,
        divisions: divisions,
        label: valueLabel,
        onChanged: onChanged,
      ),
      trailing: Text(
        valueLabel,
        style: $styles.text.bodySmall.copyWith(
          color: $styles.colors.onSurfaceVariant,
        ),
      ),
    );
  }
}
