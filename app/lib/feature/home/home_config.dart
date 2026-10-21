import 'dart:convert';

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

  /// The configuration that preserves the current home-feed behavior.
  ///
  /// Labels are stable source-neutral identifiers here. The feed data source
  /// remains the owner of localized display titles until the home consumer
  /// configuration is implemented in the follow-up issue.
  factory defaults() => HomeConfig({
    'bilibili': HomeSourceConfig(const [
      HomeTabConfig(id: 'popular', label: 'popular'),
      HomeTabConfig(id: 'ranking', label: 'ranking', sortOrder: 1),
      HomeTabConfig(id: 'live', label: 'live', sortOrder: 2),
    ], mainTabId: 'popular'),
    'youtube': HomeSourceConfig(const []),
  });

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
  static HomeConfig fromJsonOrDefault(Object? value) {
    if (value is! Map) return HomeConfig.defaults();
    try {
      return HomeConfig.fromJson(Map<String, dynamic>.from(value));
    } on Object {
      return HomeConfig.defaults();
    }
  }

  /// Reads the home configuration from the shared-preferences data source.
  static Future<HomeConfig> load(PreferencesDataSource preferences) async {
    final result = await preferences.get(PreferencesKey.homeConfig);
    if (result case Ok<String>(:final value)) {
      try {
        return fromJsonOrDefault(jsonDecode(value));
      } on FormatException {
        return HomeConfig.defaults();
      } on Object {
        return HomeConfig.defaults();
      }
    }
    return HomeConfig.defaults();
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
}
