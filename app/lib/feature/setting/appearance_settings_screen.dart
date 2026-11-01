import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';

import '../../datastore/preferences_data_source.dart';
import '../../l10n/localization_file/app_localizations.dart';
import '../../main.dart';
import 'app_settings.dart';

/// 字体缩放可选档位。
const List<double> kFontScaleOptions = [0.85, 1.0, 1.15, 1.3];

class const AppearanceSettingsScreen({super.key}) extends StatefulWidget {
  @override
  State<AppearanceSettingsScreen> createState() =>
      _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState() extends State<AppearanceSettingsScreen> {
  ThemeConfig _themeConfig = ThemeConfig.followSystem;
  double _fontScale = 1.0;
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

    final themeConfigJson = await readSetting(
      preferences,
      PreferencesKey.themeConfig,
      'FOLLOW_SYSTEM',
    );
    final fontScale = await readSetting(
      preferences,
      PreferencesKey.fontScale,
      1.0,
    );
    if (!mounted) return;
    setState(() {
      _preferences = preferences;
      _themeConfig = ThemeConfig.fromJson(themeConfigJson);
      _fontScale = fontScale;
      _loading = false;
    });
  }

  Future<void> _updateTheme(ThemeConfig config) async {
    setState(() => _themeConfig = config);
    final preferences = _preferences;
    if (preferences != null) {
      await preferences.set(PreferencesKey.themeConfig, config.toJson());
    }
  }

  Future<void> _updateFontScale(double scale) async {
    setState(() => _fontScale = scale);
    final preferences = _preferences;
    if (preferences != null) {
      await preferences.set(PreferencesKey.fontScale, scale);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsAppearance)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.symmetric(vertical: $styles.insets.xs),
              children: [
                _sectionHeader(l10n.appearanceTheme),
                _valueTile(
                  title: l10n.appearanceTheme,
                  subtitle: l10n.appearanceThemeSubtitle,
                  value: _themeLabel(l10n),
                  onTap: () => _showThemePicker(context),
                ),
                _sectionHeader(l10n.appearanceFontSize),
                _valueTile(
                  title: l10n.appearanceFontSize,
                  subtitle: l10n.appearanceFontSizeSubtitle,
                  value: _fontScaleLabel(l10n),
                  onTap: () => _showFontScalePicker(context),
                ),
                _sectionHeader(l10n.appearanceEyeComfort),
                SwitchListTile(
                  title: Text(l10n.appearanceEyeComfort),
                  subtitle: Text(l10n.appearanceEyeComfortSubtitle),
                  value: false,
                  onChanged: (_) {
                    HapticFeedback.selectionClick();
                    // L2 实现：此处仅占位，具体护眼逻辑后续迭代。
                  },
                ),
              ],
            ),
    );
  }

  String _themeLabel(AppLocalizations l10n) => switch (_themeConfig) {
    .followSystem => l10n.appearanceThemeSystem,
    .light => l10n.appearanceThemeLight,
    .dark => l10n.appearanceThemeDark,
  };

  String _fontScaleLabel(AppLocalizations l10n) => switch (_fontScale) {
    0.85 => l10n.appearanceFontSizeSmall,
    1.0 => l10n.appearanceFontSizeStandard,
    1.15 => l10n.appearanceFontSizeLarge,
    1.3 => l10n.appearanceFontSizeXLarge,
    _ => '${_fontScale}x',
  };

  void _showThemePicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            _pickerTitle(l10n.appearanceTheme),
            for (final config in ThemeConfig.values)
              _pickerOption(
                title: switch (config) {
                  .followSystem => l10n.appearanceThemeSystem,
                  .light => l10n.appearanceThemeLight,
                  .dark => l10n.appearanceThemeDark,
                },
                selected: config == _themeConfig,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _updateTheme(config);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showFontScalePicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            _pickerTitle(l10n.appearanceFontSize),
            for (final scale in kFontScaleOptions)
              _pickerOption(
                title: switch (scale) {
                  0.85 => l10n.appearanceFontSizeSmall,
                  1.0 => l10n.appearanceFontSizeStandard,
                  1.15 => l10n.appearanceFontSizeLarge,
                  1.3 => l10n.appearanceFontSizeXLarge,
                  _ => '${scale}x',
                },
                selected: scale == _fontScale,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _updateFontScale(scale);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _valueTile({
    required String title,
    required String subtitle,
    required String value,
    required VoidCallback onTap,
  }) => Tooltip(
    message: '$title: $value',
    child: ListTile(
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
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
    ),
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
    selected: selected,
    trailing: selected
        ? Icon(Icons.check, color: $styles.colors.accentText)
        : null,
    onTap: () {
      HapticFeedback.selectionClick();
      onTap();
    },
  );
}
