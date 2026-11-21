import 'dart:convert';

import 'package:data/data.dart';
import 'package:meta/meta.dart';
import 'package:model/model.dart';

import '../../datastore/preferences_data_source.dart';

/// 一个服务源上次使用的搜索筛选与排序。
@immutable
final class const SearchFilterSelection({
  required final List<FilterGroup> filters,
  required final SortOption? sortOption,
}) {
  @override
  bool operator ==(Object other) =>
      other is SearchFilterSelection &&
      _sameFilters(filters, other.filters) &&
      sortOption?.value == other.sortOption?.value;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(filters.map((group) => group.key)),
    sortOption?.value,
  );
}

bool _sameFilters(List<FilterGroup> left, List<FilterGroup> right) {
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    if (left[i].toQueryParams().toString() !=
        right[i].toQueryParams().toString()) {
      return false;
    }
  }
  return true;
}

/// 按服务源读写搜索筛选与排序。
///
/// 只持久化用户选中的 [FilterOption.value]，重建时再映射回当前数据源提供的
/// [FilterGroup] 实例，因此服务端换了一组选项也不会把旧值当成合法选项。
abstract final class SearchFilterPreferences() {
  static Future<SearchFilterSelection> load({
    required PreferencesDataSource? preferences,
    required String? sourceId,
    required List<FilterGroup> defaults,
    required List<SortOption> sortOptions,
  }) async {
    final fallbackSort = sortOptions.isEmpty ? null : sortOptions.first;
    if (preferences == null || sourceId == null) {
      return SearchFilterSelection(filters: defaults, sortOption: fallbackSort);
    }

    final stored = await _readSource(preferences, sourceId);
    if (stored == null) {
      return SearchFilterSelection(filters: defaults, sortOption: fallbackSort);
    }

    return SearchFilterSelection(
      filters: _applyFilters(defaults, stored['filters']),
      sortOption: _applySort(sortOptions, stored['sort']) ?? fallbackSort,
    );
  }

  static Future<void> save({
    required PreferencesDataSource? preferences,
    required String? sourceId,
    required List<FilterGroup> filters,
    required SortOption? sortOption,
  }) async {
    if (preferences == null || sourceId == null) return;
    final all = await _readAll(preferences);
    all[sourceId] = _encode(filters, sortOption);
    await preferences.set(PreferencesKey.searchFilters, jsonEncode(all));
  }

  static Future<Map<String, dynamic>> _readAll(
    PreferencesDataSource preferences,
  ) async {
    final result = await preferences.get(PreferencesKey.searchFilters);
    final raw = switch (result) {
      Success(:final success) => success,
      Error() => null,
    };
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : {};
    } on FormatException {
      return {};
    }
  }

  static Future<Map<String, dynamic>?> _readSource(
    PreferencesDataSource preferences,
    String sourceId,
  ) async {
    final all = await _readAll(preferences);
    final source = all[sourceId];
    return source is Map<String, dynamic> ? source : null;
  }

  static Map<String, dynamic> _encode(
    List<FilterGroup> filters,
    SortOption? sortOption,
  ) => {
    'sort': sortOption?.value,
    'filters': {for (final group in filters) group.key: _encodeGroup(group)},
  };

  static Object? _encodeGroup(FilterGroup group) => switch (group) {
    SingleFilterGroup(:final selection) => selection?.value,
    MultiFilterGroup(:final selections) => [
      for (final option in selections) option.value,
    ],
    DateRangeFilterGroup() => null,
  };

  static List<FilterGroup> _applyFilters(
    List<FilterGroup> defaults,
    Object? stored,
  ) {
    if (stored is! Map) return defaults;
    return [
      for (final group in defaults)
        switch (group) {
          SingleFilterGroup() => _applySingle(group, stored[group.key]),
          MultiFilterGroup() => _applyMulti(group, stored[group.key]),
          DateRangeFilterGroup() => group,
        },
    ];
  }

  static SingleFilterGroup _applySingle(
    SingleFilterGroup group,
    Object? stored,
  ) {
    if (stored is! String) return group;
    for (final option in group.options) {
      if (option.value == stored) {
        return group.copyWith(selection: option);
      }
    }
    return group;
  }

  static MultiFilterGroup _applyMulti(MultiFilterGroup group, Object? stored) {
    if (stored is! List) return group;
    final values = stored.whereType<String>().toSet();
    return group.copyWith(
      selections: {
        for (final option in group.options)
          if (values.contains(option.value)) option,
      },
    );
  }

  static SortOption? _applySort(List<SortOption> sortOptions, Object? stored) {
    if (stored is! String) return null;
    for (final option in sortOptions) {
      if (option.value == stored) return option;
    }
    return null;
  }
}
