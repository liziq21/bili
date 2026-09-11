abstract class SortOption {
  const SortOption(this.label);
  final String label;

  String get value;

  Map<String, String> toQueryParams();
}
