import 'package:app/datastore/media_history_settings.dart';
import 'package:app/datastore/preferences_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late PreferencesDataSource preferences;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    preferences = PreferencesDataSource(
      sharedPreferences: SharedPreferencesAsync(),
    );
  });

  tearDown(() => preferences.dispose());

  test('defaults to recording history and resuming playback', () async {
    final settings = await MediaHistorySettings.load(preferences);

    expect(settings.recordHistory, isTrue);
    expect(settings.resumePlayback, isTrue);
    expect(settings.shouldWriteHistory, isTrue);
    expect(settings.shouldReadProgress, isTrue);
  });

  test('saving both switches persists their independent values', () async {
    const saved = MediaHistorySettings(
      recordHistory: false,
      resumePlayback: true,
    );

    await saved.save(preferences);
    final loaded = await MediaHistorySettings.load(preferences);

    expect(loaded, saved);
    expect(loaded.shouldWriteHistory, isFalse);
    expect(loaded.shouldReadProgress, isFalse);
  });

  test('disabling resume keeps history writes enabled', () async {
    const saved = MediaHistorySettings(
      recordHistory: true,
      resumePlayback: false,
    );

    await saved.save(preferences);
    final loaded = await MediaHistorySettings.load(preferences);

    expect(loaded.shouldWriteHistory, isTrue);
    expect(loaded.shouldReadProgress, isFalse);
  });
}
