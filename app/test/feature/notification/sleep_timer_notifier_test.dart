import 'dart:ui' show Locale;

import 'package:app/feature/notification/notification_presenter.dart';
import 'package:app/feature/notification/sleep_timer_notifier.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

final class _RecordingPresenter() implements NotificationPresenter {
  bool supported = true;
  int permissionRequests = 0;
  final List<int> canceled = [];
  final List<
    ({
      String title,
      String body,
      String payload,
      int id,
      String channelId,
      String channelName,
    })
  >
  shown = [];

  @override
  bool get isSupported => supported;

  @override
  Future<void> initialize({
    required void Function(String? payload) onTap,
  }) async {}

  @override
  Future<({bool launched, String? payload})> launchDetails() async =>
      (launched: false, payload: null);

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return true;
  }

  @override
  Future<void> show({
    required String title,
    required String body,
    required String payload,
    int id = 0,
    String channelId = feedUpdatesChannelId,
    String channelName = feedUpdatesChannelName,
    String channelDescription = feedUpdatesChannelDescription,
  }) async {
    shown.add((
      title: title,
      body: body,
      payload: payload,
      id: id,
      channelId: channelId,
      channelName: channelName,
    ));
  }

  @override
  Future<void> cancel({int id = 0}) async {
    canceled.add(id);
  }
}

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  group('LocalSleepTimerNotifier', () {
    test('shows the warning on its own channel', () async {
      final presenter = _RecordingPresenter();
      final notifier = LocalSleepTimerNotifier(
        presenter: presenter,
        localizations: l10n,
      );

      await notifier.notifyEndingSoon();

      expect(presenter.shown, hasLength(1));
      final shown = presenter.shown.single;
      expect(shown.title, l10n.sleepTimerEndingSoonTitle);
      expect(shown.body, l10n.sleepTimerEndingSoonBody);
      expect(shown.channelId, sleepTimerChannelId);
      expect(shown.channelName, l10n.sleepTimerChannelName);
      expect(shown.payload, sleepTimerNotificationPayload);
      expect(shown.id, 1);
    });

    test('cancels the warning by id', () async {
      final presenter = _RecordingPresenter();
      final notifier = LocalSleepTimerNotifier(
        presenter: presenter,
        localizations: l10n,
      );

      await notifier.cancel();

      expect(presenter.canceled, [1]);
    });

    test('forwards the permission request', () async {
      final presenter = _RecordingPresenter();
      final notifier = LocalSleepTimerNotifier(
        presenter: presenter,
        localizations: l10n,
      );

      await notifier.requestPermission();

      expect(presenter.permissionRequests, 1);
    });

    test('stays silent on platforms without notifications', () async {
      final presenter = _RecordingPresenter()..supported = false;
      final notifier = LocalSleepTimerNotifier(
        presenter: presenter,
        localizations: l10n,
      );

      await notifier.requestPermission();
      await notifier.notifyEndingSoon();
      await notifier.cancel();

      expect(presenter.permissionRequests, 0);
      expect(presenter.shown, isEmpty);
      expect(presenter.canceled, isEmpty);
    });
  });
}
