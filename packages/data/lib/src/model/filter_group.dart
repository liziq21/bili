abstract interface class FilterOption {
  const FilterOption({required this.label, required this.value});
  final String label;
  final String value;
}

class DefaultFilterOption implements FilterOption {
  const DefaultFilterOption({required this.label, required this.value});
  @override
  final String label;
  @override
  final String value;
}

sealed class FilterGroup {
  const FilterGroup({
    required this.id,
    required this.title,
    required this.options,
  });

  final String id;
  final String title;
  final List<FilterOption> options;

  String get label => title;
}

class SingleFilterGroup extends FilterGroup {
  const SingleFilterGroup({
    required super.id,
    required super.title,
    required super.options,
    this.selection,
  });

  final FilterOption? selection;

  SingleFilterGroup copyWith({FilterOption? selection}) {
    return SingleFilterGroup(
      id: id,
      title: title,
      options: options,
      selection: selection ?? this.selection,
    );
  }
}

class MultiFilterGroup extends FilterGroup {
  const MultiFilterGroup({
    required super.id,
    required super.title,
    required super.options,
    this.selections = const {},
  });

  final Set<FilterOption> selections;

  bool isSelected(FilterOption option) => selections.contains(option);

  MultiFilterGroup copyWith({Set<FilterOption>? selections}) {
    return MultiFilterGroup(
      id: id,
      title: title,
      options: options,
      selections: selections ?? this.selections,
    );
  }
}

class DateRangeFilterGroup extends FilterGroup {
  const DateRangeFilterGroup({
    required super.id,
    required super.title,
    super.options = const [],
    this.range,
  });

  final ({DateTime start, DateTime end})? range;

  DateRangeFilterGroup copyWith(({DateTime start, DateTime end})? range) {
    return DateRangeFilterGroup(
      id: id,
      title: title,
      options: options,
      range: range ?? this.range,
    );
  }
}

extension FilterGroupQueryParams on FilterGroup {
  Map<String, String> toQueryParams() {
    return {};
  }
}
