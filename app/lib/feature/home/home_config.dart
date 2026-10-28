import 'dart:convert';

import 'package:data/data.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:model/model.dart';

import '../../datastore/preferences_data_source.dart';

/// A configurable tab in a service source's home feed.
@immutable
class const HomeTabConfig({
  required final String id,
  required final String label,
  final bool isVisible = true,
  final int sortOrder = 0,
}) extends Equatable {
  factory fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final label = json['label'];
    final isVisible = json['isVisible'];
    final sortOrder = json['sortOrder'];

    if (id is! String || id.isEmpty) {
      throw const FormatException('Home tab id must be a non-empty string');
    }
    if (label is! String || label.isEmpty) {
      throw const FormatException('Home tab label must be a non-empty string');
    }
    if (isVisible != null && isVisible is! bool) {
      throw const FormatException('Home tab visibility must be a boolean');
    }
    if (sortOrder != null || json.containsKey('sortOrder')) {
      if (sortOrder is! int || sortOrder < 0) {
        throw const FormatException('Home tab sort order must be non-negative');
      }
    }

    return HomeTabConfig(
      id: id,
      label: label,
      isVisible: isVisible as bool? ?? true,
      sortOrder: sortOrder as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'isVisible': isVisible,
    'sortOrder': sortOrder,
  };

  @override
  List<Object?> get props => [id, label, isVisible, sortOrder];
}

/// The home-feed configuration belonging to one service source.
@immutable
class HomeSourceConfig(
  Iterable<HomeTabConfig> rawTabs, {
  final String? mainTabId,
}) extends Equatable {
  this : tabs = List.unmodifiable(rawTabs) {
    final ids = <String>{};
    for (final tab in tabs) {
      if (!ids.add(tab.id)) {
        throw ArgumentError.value(tab.id, 'tabs', 'Duplicate home tab id');
      }
    }
    if (mainTabId != null && !ids.contains(mainTabId)) {
      throw ArgumentError.value(
        mainTabId,
        'mainTabId',
        'Main tab must be one of the configured tabs',
      );
    }
  }

  factory fromJson(Map<String, dynamic> json) {
    final rawTabs = json['tabs'];
    final rawMainTabId = json['mainTabId'];

    if (rawTabs is! List) {
      throw const FormatException('Home source tabs must be a list');
    }
    if (rawMainTabId != null && rawMainTabId is! String) {
      throw const FormatException('Home source main tab must be a string');
    }

    return HomeSourceConfig([
      for (final rawTab in rawTabs)
        if (rawTab is Map)
          HomeTabConfig.fromJson(Map<String, dynamic>.from(rawTab))
        else
          throw const FormatException('Home tab must be an object'),
    ], mainTabId: rawMainTabId as String?);
  }

  final List<HomeTabConfig> tabs;

  Map<String, dynamic> toJson() => {
    'tabs': [for (final tab in tabs) tab.toJson()],
    'mainTabId': mainTabId,
  };

  @override
  List<Object?> get props => [tabs, mainTabId];
}

/// User-editable configuration for all service-source home feeds.
@immutable
class HomeConfig(
  Map<String, HomeSourceConfig> rawSources, {
  final int gridColumnsPortrait = 2,
  final int gridColumnsLandscape = 2,
}) extends Equatable {
  this : sources = Map.unmodifiable(rawSources) {
    for (final sourceId in sources.keys) {
      if (sourceId.isEmpty) {
        throw ArgumentError('Home source id must be non-empty');
      }
    }
    _validateGridColumns(gridColumnsPortrait, 'gridColumnsPortrait');
    _validateGridColumns(gridColumnsLandscape, 'gridColumnsLandscape');
  }

  /// Builds the configuration that preserves the current home-feed behavior.
  ///
  /// Feed sources own their display titles, so defaults are derived from the
  /// same source capabilities that currently populate the home state. This keeps
  /// localized/source-specific labels out of app code and prevents a default
  /// migration from replacing them with internal feed IDs.
  factory defaults({Iterable<MediaSource> sources = const []}) {
    return HomeConfig({
      for (final source in sources) source.id: _sourceDefaults(source),
    });
  }

  factory fromJson(Map<String, dynamic> json) {
    final rawSources = json['sources'];
    final portrait = json['gridColumnsPortrait'];
    final landscape = json['gridColumnsLandscape'];

    if (rawSources is! Map) {
      throw const FormatException('Home sources must be an object');
    }
    if (portrait is! int || landscape is! int) {
      throw const FormatException('Home grid columns must be integers');
    }

    final sources = <String, HomeSourceConfig>{};
    for (final entry in rawSources.entries) {
      if (entry.key is! String || entry.value is! Map) {
        throw const FormatException('Home source must be an object');
      }
      final sourceId = entry.key as String;
      final sourceJson = Map<String, dynamic>.from(entry.value as Map);
      sources[sourceId] = HomeSourceConfig.fromJson(sourceJson);
    }

    return HomeConfig(
      sources,
      gridColumnsPortrait: portrait,
      gridColumnsLandscape: landscape,
    );
  }

  final Map<String, HomeSourceConfig> sources;

  /// Decodes persisted data and returns defaults for malformed or incompatible
  /// values. A bad preference must not prevent the app from starting.
  static HomeConfig fromJsonOrDefault(Object? value, {HomeConfig? fallback}) {
    final defaultConfig = fallback ?? HomeConfig.defaults();
    if (value is! Map) return defaultConfig;
    try {
      return HomeConfig.fromJson(Map<String, dynamic>.from(value));
    } on Object {
      return defaultConfig;
    }
  }

  /// Reads the home configuration from the shared-preferences data source.
  static Future<HomeConfig> load(
    PreferencesDataSource preferences, {
    Iterable<MediaSource> sources = const [],
  }) async {
    final defaults = HomeConfig.defaults(sources: sources);
    final result = await preferences.get(PreferencesKey.homeConfig);
    if (result case Ok<String>(:final value)) {
      try {
        return fromJsonOrDefault(jsonDecode(value), fallback: defaults);
      } on FormatException {
        return defaults;
      } on Object {
        return defaults;
      }
    }
    return defaults;
  }

  Future<Result<void>> save(PreferencesDataSource preferences) {
    return preferences.set(PreferencesKey.homeConfig, jsonEncode(toJson()));
  }

  Map<String, dynamic> toJson() => {
    'sources': {
      for (final MapEntry(:key, :value) in sources.entries) key: value.toJson(),
    },
    'gridColumnsPortrait': gridColumnsPortrait,
    'gridColumnsLandscape': gridColumnsLandscape,
  };

  @override
  List<Object?> get props => [
    sources,
    gridColumnsPortrait,
    gridColumnsLandscape,
  ];

  static void _validateGridColumns(int value, String name) {
    if (value < 1 || value > 8) {
      throw ArgumentError.value(
        value,
        name,
        'Grid columns must be between 1 and 8',
      );
    }
  }

  static HomeSourceConfig _sourceDefaults(MediaSource source) {
    final tabs = <HomeTabConfig>[];
    for (final feed in source.videoFeedDataSources) {
      tabs.add(
        HomeTabConfig(
          id: _uniqueTabId(tabs, feed.id, 'video'),
          label: feed.title,
          sortOrder: tabs.length,
        ),
      );
    }
    for (final feed in source.liveRoomFeedDataSources) {
      tabs.add(
        HomeTabConfig(
          id: _uniqueTabId(tabs, feed.id, 'live'),
          label: feed.title,
          sortOrder: tabs.length,
        ),
      );
    }

    return HomeSourceConfig(tabs, mainTabId: tabs.firstOrNull?.id);
  }

  static String _uniqueTabId(
    List<HomeTabConfig> tabs,
    String feedId,
    String kind,
  ) {
    final existingIds = tabs.map((tab) => tab.id).toSet();
    if (!existingIds.contains(feedId)) return feedId;

    var suffix = 2;
    var candidate = '$feedId:$kind';
    while (existingIds.contains(candidate)) {
      candidate = '$feedId:$kind$suffix';
      suffix++;
    }
    return candidate;
  }
}

/// Editing operations on [HomeConfig], shared by the editor screen and tests.
///
/// Each operation returns a new [HomeConfig]; the editor persists the result
/// and the widget test / unit tests assert on the returned value directly.
extension HomeConfigEditorX on HomeConfig {
  /// Returns a copy with [tabId]'s visibility set to [visible].
  HomeConfig withTabVisible(String sourceId, String tabId, bool visible) {
    final source = sources[sourceId];
    if (source == null) return this;
    final tabs = [
      for (final tab in source.tabs)
        if (tab.id == tabId)
          HomeTabConfig(
            id: tab.id,
            label: tab.label,
            isVisible: visible,
            sortOrder: tab.sortOrder,
          )
        else
          tab,
    ];
    return withSource(
      sourceId,
      HomeSourceConfig(tabs, mainTabId: source.mainTabId),
    );
  }

  /// Returns a copy with [tabId] moved one position up ([up] == true) or down.
  ///
  /// Moves by swapping sort orders with the neighbour in the current order.
  /// Returns [this] unchanged when the tab is missing or already at the edge.
  HomeConfig withTabMoved(String sourceId, String tabId, bool up) {
    final source = sources[sourceId];
    if (source == null) return this;
    final ordered = [...source.tabs]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final index = ordered.indexWhere((tab) => tab.id == tabId);
    final targetIndex = up ? index - 1 : index + 1;
    if (index < 0 || targetIndex < 0 || targetIndex >= ordered.length) {
      return this;
    }
    final other = ordered[targetIndex];
    final swapped = [
      for (final tab in source.tabs)
        if (tab.id == tabId)
          HomeTabConfig(
            id: tab.id,
            label: tab.label,
            isVisible: tab.isVisible,
            sortOrder: other.sortOrder,
          )
        else if (tab.id == other.id)
          HomeTabConfig(
            id: tab.id,
            label: tab.label,
            isVisible: tab.isVisible,
            sortOrder: ordered[index].sortOrder,
          )
        else
          tab,
    ];
    return withSource(
      sourceId,
      HomeSourceConfig(swapped, mainTabId: source.mainTabId),
    );
  }

  /// Returns a copy with [tabId] set as the source's main tab.
  HomeConfig withMainTab(String sourceId, String tabId) {
    final source = sources[sourceId];
    if (source == null || source.mainTabId == tabId) return this;
    return withSource(
      sourceId,
      HomeSourceConfig(source.tabs, mainTabId: tabId),
    );
  }

  /// Returns a copy with the per-orientation grid columns replaced.
  HomeConfig withGridColumns({required int portrait, required int landscape}) {
    return HomeConfig(
      sources,
      gridColumnsPortrait: portrait,
      gridColumnsLandscape: landscape,
    );
  }

  /// Returns a copy with [sourceId] replaced by [source].
  HomeConfig withSource(String sourceId, HomeSourceConfig source) {
    return HomeConfig(
      {...sources, sourceId: source},
      gridColumnsPortrait: gridColumnsPortrait,
      gridColumnsLandscape: gridColumnsLandscape,
    );
  }
}
