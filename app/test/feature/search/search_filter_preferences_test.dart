import 'dart:convert';

import 'package:app/datastore/preferences_data_source.dart';
import 'package:app/feature/search/search_filter_preferences.dart';
import 'package:bilibili/bilibili.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PreferencesDataSource preferences;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    preferences = PreferencesDataSource(
      sharedPreferences: SharedPreferencesAsync(),
    );
  });

  tearDown(() => preferences.dispose());

  List<FilterGroup> defaults() => const [VideoDurationFilter()];

  test('round-trips the selected duration and sort for one source', () async {
    await SearchFilterPreferences.save(
      preferences: preferences,
      sourceId: 'bilibili',
      filters: [
        const VideoDurationFilter().copyWith(
          selection: VideoDurationFilterOption.tenTo30Minutes,
        ),
      ],
      sortOption: PhotoOrVideoSearchSort.dm,
    );

    final loaded = await SearchFilterPreferences.load(
      preferences: preferences,
      sourceId: 'bilibili',
      defaults: defaults(),
      sortOptions: PhotoOrVideoSearchSort.values,
    );

    expect(
      (loaded.filters.single as SingleFilterGroup).selection,
      VideoDurationFilterOption.tenTo30Minutes,
    );
    expect(loaded.sortOption, PhotoOrVideoSearchSort.dm);
  });

  test('keeps sources isolated from each other', () async {
    await SearchFilterPreferences.save(
      preferences: preferences,
      sourceId: 'bilibili',
      filters: [
        const VideoDurationFilter().copyWith(
          selection: VideoDurationFilterOption.below10Minutes,
        ),
      ],
      sortOption: PhotoOrVideoSearchSort.click,
    );

    final loaded = await SearchFilterPreferences.load(
      preferences: preferences,
      sourceId: 'youtube',
      defaults: defaults(),
      sortOptions: PhotoOrVideoSearchSort.values,
    );

    expect(
      (loaded.filters.single as SingleFilterGroup).selection,
      VideoDurationFilterOption.allDuration,
    );
    expect(loaded.sortOption, PhotoOrVideoSearchSort.totalrank);
  });

  test('falls back when stored values no longer exist', () async {
    await preferences.set(
      PreferencesKey.searchFilters,
      jsonEncode({
        'bilibili': {
          'sort': 'removedSort',
          'filters': {'duration': 'removedOption'},
        },
      }),
    );

    final loaded = await SearchFilterPreferences.load(
      preferences: preferences,
      sourceId: 'bilibili',
      defaults: defaults(),
      sortOptions: PhotoOrVideoSearchSort.values,
    );

    expect(
      (loaded.filters.single as SingleFilterGroup).selection,
      VideoDurationFilterOption.allDuration,
    );
    expect(loaded.sortOption, PhotoOrVideoSearchSort.totalrank);
  });

  test('returns defaults without a preferences store', () async {
    final loaded = await SearchFilterPreferences.load(
      preferences: null,
      sourceId: null,
      defaults: defaults(),
      sortOptions: PhotoOrVideoSearchSort.values,
    );

    expect(loaded.filters, defaults());
    expect(loaded.sortOption, PhotoOrVideoSearchSort.totalrank);
  });
}
