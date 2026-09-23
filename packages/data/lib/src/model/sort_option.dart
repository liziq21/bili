abstract class const SortOption(final String label) {
  String get value;

  Map<String, String> toQueryParams();
}
