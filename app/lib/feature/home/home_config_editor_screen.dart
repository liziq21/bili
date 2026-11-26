import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../datastore/preferences_data_source.dart';
import '../../design/design.dart';
import '../../l10n/localization_file/app_localizations.dart';
import '../../main.dart';
import '../../providers/media_sources_provider.dart';
import '../setting/common_widgets/setting_tiles.dart';
import 'home_config.dart';

/// Home feed configuration editor: feed tab visibility, ordering, main tab
/// selection and grid columns per orientation.
///
/// Edits are persisted immediately via [HomeConfig.save]; the page re-reads
/// the configuration on every mount, so an edit survives an app restart.
class const HomeConfigEditorScreen({super.key}) extends StatefulWidget {
  @override
  State<HomeConfigEditorScreen> createState() => _HomeConfigEditorScreenState();
}

class _HomeConfigEditorScreenState() extends State<HomeConfigEditorScreen> {
  HomeConfig _config = HomeConfig({});
  PreferencesDataSource? _preferences;
  List<MediaSourceDefinition> _sources = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    PreferencesDataSource? preferences;
    List<MediaSourceDefinition> sources = const [];
    try {
      preferences = context.read<PreferencesDataSource>();
      sources = context.read<MediaSourceCatalog>().definitions;
    } on Object catch (_) {
      // Keep the page usable in isolated widget tests without app providers.
    }

    if (preferences == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final config = await HomeConfig.load(
      preferences,
      sources: sources.map((definition) => definition.create()),
    );
    if (!mounted) return;
    setState(() {
      _preferences = preferences;
      _sources = sources;
      _config = config;
      _loading = false;
    });
  }

  Future<void> _persist(HomeConfig updated) async {
    setState(() => _config = updated);
    final preferences = _preferences;
    if (preferences != null) await updated.save(preferences);
  }

  Future<void> _setTabVisible(
    String sourceId,
    String tabId,
    bool visible,
  ) async {
    await _persist(_config.withTabVisible(sourceId, tabId, visible));
  }

  Future<void> _moveTab(String sourceId, String tabId, bool up) async {
    await _persist(_config.withTabMoved(sourceId, tabId, up));
  }

  Future<void> _setMainTab(String sourceId, String tabId) async {
    await _persist(_config.withMainTab(sourceId, tabId));
  }

  Future<void> _setGridColumns({
    required int portrait,
    required int landscape,
  }) async {
    await _persist(
      _config.withGridColumns(portrait: portrait, landscape: landscape),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeConfigTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.symmetric(vertical: $styles.insets.xs),
              children: [
                _gridColumnsSection(l10n),
                for (final source in _sources)
                  if (_config.sources[source.id] != null)
                    _sourceSection(l10n, source),
              ],
            ),
    );
  }

  Widget _gridColumnsSection(AppLocalizations l10n) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SettingSectionHeader(title: l10n.homeConfigGridColumns),
      SettingValueTile(
        title: l10n.homeConfigPortrait,
        value: '${_config.gridColumnsPortrait}',
        onTap: () => _showColumnPicker(
          l10n.homeConfigPortrait,
          selected: _config.gridColumnsPortrait,
          onSelected: (value) => _setGridColumns(
            portrait: value,
            landscape: _config.gridColumnsLandscape,
          ),
        ),
      ),
      SettingValueTile(
        title: l10n.homeConfigLandscape,
        value: '${_config.gridColumnsLandscape}',
        onTap: () => _showColumnPicker(
          l10n.homeConfigLandscape,
          selected: _config.gridColumnsLandscape,
          onSelected: (value) => _setGridColumns(
            portrait: _config.gridColumnsPortrait,
            landscape: value,
          ),
        ),
      ),
    ],
  );

  Future<void> _showColumnPicker(
    String title, {
    required int selected,
    required ValueChanged<int> onSelected,
  }) => showSettingPicker<int>(
    context: context,
    title: title,
    selected: selected,
    choices: [
      for (var columns = 1; columns <= 8; columns++)
        SettingPickerChoice(columns, '$columns'),
    ],
    onSelected: onSelected,
  );

  Widget _sourceSection(AppLocalizations l10n, MediaSourceDefinition source) {
    final sourceConfig = _config.sources[source.id]!;
    final orderedTabs = [...sourceConfig.tabs]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return Card(
      margin: EdgeInsets.symmetric(vertical: $styles.insets.sm),
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.symmetric(
          horizontal: $styles.insets.md,
          vertical: $styles.insets.sm,
        ),
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: $styles.insets.sm),
            child: Text(source.name, style: $styles.text.bodySmallBold),
          ),
          if (orderedTabs.isEmpty)
            Padding(
              padding: EdgeInsets.only(top: $styles.insets.xs),
              child: Text(l10n.homeConfigNoTabs, style: $styles.text.caption),
            )
          else ...[
            Text(l10n.homeConfigTabs, style: $styles.text.caption),
            for (var index = 0; index < orderedTabs.length; index++)
              Padding(
                // 稳定 key 让重排后的行保持同一个 Element，读屏焦点不会留在
                // 原位置而改指向另一个标签。
                key: ValueKey('${source.id}-${orderedTabs[index].id}'),
                padding: EdgeInsets.symmetric(vertical: $styles.insets.xs),
                child: _tabRow(
                  l10n: l10n,
                  tab: orderedTabs[index],
                  isFirst: index == 0,
                  isLast: index == orderedTabs.length - 1,
                  isMain: orderedTabs[index].id == sourceConfig.mainTabId,
                  sourceId: source.id,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _tabRow({
    required AppLocalizations l10n,
    required HomeTabConfig tab,
    required bool isFirst,
    required bool isLast,
    required bool isMain,
    required String sourceId,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Semantics(
          label:
              '${tab.label} ${tab.isVisible ? l10n.homeConfigVisible : l10n.homeConfigHidden}',
          child: Switch(
            value: tab.isVisible,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              _setTabVisible(sourceId, tab.id, value);
            },
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tab.label, style: $styles.text.bodySmall),
              if (isMain)
                Text(l10n.homeConfigSetMain, style: $styles.text.caption),
            ],
          ),
        ),
        _semanticIconButton(
          label: '${l10n.homeConfigSetMain}: ${tab.label}',
          tooltip: l10n.homeConfigSetMain,
          icon: Icon(
            isMain ? AppIcons.mainSectionSelected : AppIcons.mainSection,
            size: 18.0,
          ),
          onPressed: isMain
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  _setMainTab(sourceId, tab.id);
                },
        ),
        _semanticIconButton(
          label: '${l10n.homeConfigMoveUp}: ${tab.label}',
          tooltip: l10n.homeConfigMoveUp,
          icon: const Icon(AppIcons.moveUp, size: 18),
          onPressed: isFirst
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  _moveTab(sourceId, tab.id, true);
                },
        ),
        _semanticIconButton(
          label: '${l10n.homeConfigMoveDown}: ${tab.label}',
          tooltip: l10n.homeConfigMoveDown,
          icon: const Icon(AppIcons.moveDown, size: 18),
          onPressed: isLast
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  _moveTab(sourceId, tab.id, false);
                },
        ),
      ],
    );
  }

  /// `excludeSemantics` 会丢掉 `IconButton` 自己的 tap 动作，所以同一个回调要
  /// 同时交给语义节点和按钮；禁用时两处都传 null，读屏才不会读出一个点不动的按钮。
  Widget _semanticIconButton({
    required String label,
    required String tooltip,
    required Widget icon,
    required VoidCallback? onPressed,
  }) => Semantics(
    label: label,
    button: true,
    enabled: onPressed != null,
    onTap: onPressed,
    excludeSemantics: true,
    child: IconButton(icon: icon, tooltip: tooltip, onPressed: onPressed),
  );
}
