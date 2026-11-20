import 'dart:async';

import 'package:app/feature/notification/feed_notification_listener.dart';
import 'package:app/feature/notification/feed_update_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';
import 'package:provider/provider.dart';

/// 点击事件源与初始化调用的最小替身。
///
/// 只暴露 listener 实际读取的两个成员：点击流与 `initialize`。
final class _FakeNotifier() implements FeedUpdateNotifier {
  final _opened = StreamController<void>.broadcast();
  int initializeCalls = 0;

  @override
  bool get isSupported => true;

  @override
  Stream<void> get feedOpened => _opened.stream;

  /// 模拟一次点击。
  ///
  /// widget 测试跑在假时钟上，`Future.delayed` 不会被推进；broadcast 流的派发
  /// 只需要一个微任务，交给 `tester.pump()` 冲刷即可。
  void tap() => _opened.add(null);

  @override
  Future<Result<void, Exception>> initialize() async {
    initializeCalls++;
    return const Result.success(null);
  }

  @override
  Future<Result<bool, Exception>> requestPermission() async =>
      const Result.success(true);

  @override
  Future<Result<int, Exception>> notifyIfThresholdReached({
    required int currentCount,
    required int threshold,
    required int lastNotifiedCount,
  }) async => Result.success(lastNotifiedCount);

  @override
  Future<void> dispose() async => _opened.close();
}

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required FeedUpdateNotifier notifier,
    required VoidCallback onOpenFeed,
  }) => tester.pumpWidget(
    Provider<FeedUpdateNotifier>.value(
      value: notifier,
      child: MaterialApp(
        home: FeedNotificationListener(
          onOpenFeed: onOpenFeed,
          child: const SizedBox.shrink(),
        ),
      ),
    ),
  );

  testWidgets('a tapped notification asks the shell to open the feed', (
    tester,
  ) async {
    // Given the listener is mounted over the navigation shell.
    final notifier = _FakeNotifier();
    addTearDown(notifier.dispose);
    var opened = 0;
    await pump(tester, notifier: notifier, onOpenFeed: () => opened++);

    // When the platform reports a notification tap.
    notifier.tap();
    await tester.pump();

    // Then the shell is asked to switch to the feed branch exactly once.
    expect(opened, 1);
  });

  testWidgets('mounting the listener initializes the notifier once', (
    tester,
  ) async {
    // Given a fresh notifier.
    final notifier = _FakeNotifier();
    addTearDown(notifier.dispose);

    // When the shell mounts.
    await pump(tester, notifier: notifier, onOpenFeed: () {});
    await tester.pump();

    // Then the channel is prepared without waiting for a user action.
    expect(notifier.initializeCalls, 1);
  });

  testWidgets('unmounting stops routing further taps', (tester) async {
    // Given a mounted listener that already handled one tap.
    final notifier = _FakeNotifier();
    addTearDown(notifier.dispose);
    var opened = 0;
    await pump(tester, notifier: notifier, onOpenFeed: () => opened++);
    notifier.tap();
    await tester.pump();
    expect(opened, 1);

    // When the shell goes away.
    await tester.pumpWidget(const SizedBox.shrink());
    notifier.tap();
    await tester.pump();

    // Then later taps do not reach a disposed listener.
    expect(opened, 1);
  });

  testWidgets('a missing notifier provider does not crash the shell', (
    tester,
  ) async {
    // Given the app tree has no FeedUpdateNotifier (unsupported build, tests).
    // When the shell mounts.
    await tester.pumpWidget(
      const MaterialApp(
        home: FeedNotificationListener(child: SizedBox.shrink()),
      ),
    );

    // Then the shell still renders.
    expect(tester.takeException(), isNull);
  });
}
