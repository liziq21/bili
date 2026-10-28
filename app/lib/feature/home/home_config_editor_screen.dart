import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../datastore/preferences_data_source.dart';
import '../../l10n/localization_file/app_localizations.dart';
import '../../main.dart';
import '../../providers/media_sources_provider.dart';
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

  Widget _gridColumnsSection(AppLocalizations l10n) {
    return ListTile(
      leading: Icon(Icons.grid_view, color: $styles.colors.onSurfaceVariant),
      title: Text(l10n.homeConfigGridColumns, style: $styles.text.body),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _columnPicker(
            l10n.homeConfigPortrait,
            _config.gridColumnsPortrait,
            (value) => _setGridColumns(
              portrait: value,
              landscape: _config.gridColumnsLandscape,
            ),
          ),
          _columnPicker(
            l10n.homeConfigLandscape,
            _config.gridColumnsLandscape,
            (value) => _setGridColumns(
              portrait: _config.gridColumnsPortrait,
              landscape: value,
            ),
          ),
        ],
      ),
    );
  }

  Widget _columnPicker(String label, int value, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          DropdownButton<int>(
            value: value,
            items: [
              for (var columns = 1; columns <= 8; columns++)
                DropdownMenuItem(value: columns, child: Text('$columns')),
            ],
            onChanged: (updated) {
              if (updated != null) onChanged(updated);
            },
          ),
        ],
      ),
    );
  }

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
          Text(l10n.homeConfigTabs, style: $styles.text.caption),
          for (var index = 0; index < orderedTabs.length; index++)
            Padding(
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
        Switch(
          value: tab.isVisible,
          onChanged: (value) => _setTabVisible(sourceId, tab.id, value),
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
        IconButton(
          icon: Icon(isMain ? Icons.star : Icons.star_border, size: 18.0),
          tooltip: l10n.homeConfigSetMain,
          onPressed: isMain ? null : () => _setMainTab(sourceId, tab.id),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_upward, size: 18),
          tooltip: l10n.homeConfigMoveUp,
          onPressed: isFirst ? null : () => _moveTab(sourceId, tab.id, true),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_downward, size: 18),
          tooltip: l10n.homeConfigMoveDown,
          onPressed: isLast ? null : () => _moveTab(sourceId, tab.id, false),
        ),
      ],
    );
  }
}
