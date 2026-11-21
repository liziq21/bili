import 'package:app/datastore/preferences_data_source.dart';
import 'package:app/feature/setting/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  group(ChannelTabSettings, () {
    test('treats an unknown tab id as visible', () {
      // Given an empty persisted setting.
      const settings = ChannelTabSettings();

      // When asking about a tab the setting never mentioned.
      // Then the tab stays visible so new tabs are not hidden by old data.
      expect(settings.isVisible(ChannelTabs.videos), isTrue);
    });

    test('keeps only boolean entries when decoding JSON', () {
      // Given a map with one valid and two malformed entries.
      final settings = ChannelTabSettings.fromJson({
        ChannelTabs.videos: false,
        'not-a-bool': 'hidden',
        42: true,
      });

      // Then only the boolean entry affects visibility.
      expect(settings.isVisible(ChannelTabs.videos), isFalse);
      expect(settings.isVisible('not-a-bool'), isTrue);
    });

    test('falls back to defaults for malformed JSON text', () {
      // When decoding a string that is not JSON.
      final settings = ChannelTabSettings.fromJsonString('not-json');

      // Then every tab remains visible.
      expect(settings.isVisible(ChannelTabs.videos), isTrue);
    });

    group('persistence', () {
      late PreferencesDataSource preferences;

      setUp(() {
        SharedPreferencesAsyncPlatform.instance =
            InMemorySharedPreferencesAsync.empty();
        preferences = PreferencesDataSource(
          sharedPreferences: SharedPreferencesAsync(),
        );
      });

      tearDown(() => preferences.dispose());

      test('persists a hidden tab and reads it back', () async {
        // Given a setting that hides the videos tab.
        const settings = ChannelTabSettings(
          visibility: {ChannelTabs.videos: false},
        );

        // When saving and loading it through the preferences data source.
        await settings.save(preferences);
        final loaded = await ChannelTabSettings.load(preferences);

        // Then the hidden state survives the round trip.
        expect(loaded.isVisible(ChannelTabs.videos), isFalse);
      });

      test('returns defaults when the stored value is invalid', () async {
        // Given a corrupt value under the channel tab key.
        await preferences.set(PreferencesKey.channelTabVisibility, 'not-json');

        // When loading the settings.
        final loaded = await ChannelTabSettings.load(preferences);

        // Then the corrupt value is treated as the default configuration.
        expect(loaded.isVisible(ChannelTabs.videos), isTrue);
      });
    });
  });
}
