import 'preferences_data_source.dart';

abstract interface class PreferencesKeySet<T> {
  const PreferencesKeySet();

  List<PreferencesKey<Object?>> get keys;

  T fromJson(Map<String, Object?> jsom);
}
