@immutable
abstract class FilterGroup {
  FilterGroup({
    required this.label,
    required this.options,
    this.allowMultipleSelection = false,
    this.defaultSelectedOption,
    this.selectedOptions = const [],
  });
  
  final String label;
  final List<FilterOption> options;
  final bool allowMultipleSelection;
  final FilterOption? defaultSelectedOption;
  final List<FilterOption> selectedOptions;
}

@immutable
abstract class FilterOption {
  FilterOption({required this.label});
  
  final String label;
}

@immutable
class DateRangePresetOption extends FilterOption {
  const DateRangePresetOption({
    required super.label,
    this.dateRange,
  });
  
  final ({DateTime start, DateTime end})? dateRange;
}

@immutable
class DateRangeFilter extends FilterGroup {
  DateRangeFilter({
    required super.label,
    super.options = const [],
    super.allowMultipleSelection = false,
    super.defaultSelectedOption,
    super.selectedOptions = const [],
    this.customDateRange,
  });
  
  final ({DateTime start, DateTime end})? customDateRange;

  bool get hasCustomRange => customDateRange != null;
}