import 'preferences_data_source.dart';

abstract interface class const PreferencesKeySet<T>() {
  List<PreferencesKey<Object?>> get keys;

  T fromJson(Map<String, Object?> jsom);
}
