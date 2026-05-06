import 'package:meta/meta.dart';

@immutable
abstract interface class FilterOption {
  const FilterOption({required this.label});

  final String label;

  String get value;

  @override
  bool operator ==(Object other) =>
      other is FilterOption &&
      runtimeType == other.runtimeType &&
      value == other.value;

  @override
  int get hashCode => value.hashCode;
}

@immutable
sealed class FilterGroup {
  const FilterGroup({required this.key, required this.label});

  final String key;
  final String label;

  Map<String, String> toQueryParams();

  FilterGroup copyWith();
}

class SingleFilterGroup extends FilterGroup {
  const SingleFilterGroup({
    required super.key,
    required super.label,
    required this.options,
    this.selection,
  });

  final List<FilterOption> options;
  final FilterOption? selection;

  @override
  Map<String, String> toQueryParams() => {key: ?selection?.value};

  @override
  SingleFilterGroup copyWith({FilterOption? selection, bool clear = false}) {
    return SingleFilterGroup(
      key: key,
      label: label,
      options: options,
      selection: clear ? null : (selection ?? this.selection),
    );
  }
}

class MultiFilterGroup extends FilterGroup {
  const MultiFilterGroup({
    required super.key,
    required super.label,
    required this.options,
    this.selections = const {},
  });

  final List<FilterOption> options;
  final Set<FilterOption> selections;

  @override
  Map<String, String> toQueryParams() {
    // 假设多选在 URL 中是 "key=v1,v2"
    return {
      if (selections.isNotEmpty) key: selections.map((e) => e.value).join(','),
    };
  }

  @override
  MultiFilterGroup copyWith({Set<FilterOption>? selections}) {
    return MultiFilterGroup(
      key: key,
      label: label,
      options: options,
      selections: selections ?? this.selections,
    );
  }
}

typedef DateRange = ({DateTime start, DateTime end});

class DateRangeFilterGroup extends FilterGroup {
  const DateRangeFilterGroup({
    required super.key,
    required super.label,
    this.range,
  });

  final DateRange? range;

  @override
  DateRangeFilterGroup copyWith({DateRange? range}) {
    return .new(key: key, label: label, range: range);
  }

  @override
  Map<String, String> toQueryParams() {
    return {key: range.toString()};
  }
}
