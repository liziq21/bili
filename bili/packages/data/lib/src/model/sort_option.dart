import 'package:meta/meta.dart';

@immutable
abstract class SortOption {
  const SortOption({required this.label});

  final String label;

  String get value;
  
  Map<String, String> toQueryParams();
}