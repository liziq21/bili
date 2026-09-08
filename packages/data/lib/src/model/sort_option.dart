abstract class const SortOption({required final String label}) {
  String get value;

  Map<String, String> toQueryParams();
}
