import 'dart:async';

import 'package:app/utils/command.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:model/model.dart';

/// Regression tests for the `Command` base class.
///
/// `Command` is the only thing standing between a double-tapped button and two
/// identical in-flight requests: `_execute` returns early when `_running` is
/// already true. That guard is invisible in review because nothing about the
/// signature changes if it is deleted, so it gets pinned here along with the
/// `running` / `error` / `completed` state the UI binds to.
void main() {
  group('Command0', () {
    test('starts idle and reports no result', () {
      final command = Command0<int>(() async => Result<int>.ok(1));

      expect(command.running, isFalse);
      expect(command.completed, isFalse);
      expect(command.error, isFalse);
      expect(command.result, isNull);
    });

    test('exposes completed after a successful action', () async {
      final command = Command0<int>(() async => Result<int>.ok(7));

      await command.execute();

      expect(command.running, isFalse);
      expect(command.completed, isTrue);
      expect(command.error, isFalse);
      expect(command.result, isA<Ok<int>>());
      expect((command.result! as Ok<int>).value, 7);
    });

    test('exposes error after a failed action', () async {
      final command = Command0<int>(
        () async => Result<int>.error(Exception('boom')),
      );

      await command.execute();

      expect(command.running, isFalse);
      expect(command.error, isTrue);
      expect(command.completed, isFalse);
      expect((command.result! as Error<int>).error, isA<Exception>());
    });

    test('drops a concurrent second invocation while the first is in '
        'flight', () async {
      // The guard is the point of the class: a second execute() arriving
      // before the first completes must not start a second request.
      final gate = Completer<Result<int>>();
      var calls = 0;

      final command = Command0<int>(() {
        calls++;
        return gate.future;
      });

      final first = command.execute();
      expect(command.running, isTrue, reason: 'must be busy while awaiting');

      await command.execute();
      expect(calls, 1, reason: 'the second invocation must be dropped');

      gate.complete(Result<int>.ok(1));
      await first;

      expect(calls, 1);
      expect(command.running, isFalse);
      expect((command.result! as Ok<int>).value, 1);
    });

    test('accepts a new invocation once the previous one settled', () async {
      var calls = 0;
      final command = Command0<int>(() async {
        calls++;
        return Result<int>.ok(calls);
      });

      await command.execute();
      await command.execute();

      expect(calls, 2, reason: 'the guard must release after settling');
      expect((command.result! as Ok<int>).value, 2);
    });

    test('drops the previous result at the start of the next run', () async {
      var failNext = false;
      final command = Command0<int>(() async {
        if (failNext) {
          failNext = false;
          return Result<int>.error(Exception('boom'));
        }
        return Result<int>.ok(1);
      });

      await command.execute();
      expect(command.completed, isTrue);

      failNext = true;
      await command.execute();

      expect(command.error, isTrue);
      expect(command.completed, isFalse);
    });

    test('notifies listeners when running flips on and off', () async {
      final command = Command0<int>(() async => Result<int>.ok(1));
      var notifications = 0;
      command.addListener(() => notifications++);

      await command.execute();

      // One notification for entering the running state, one for leaving it.
      expect(notifications, 2);
    });

    test('clearResult drops the result and notifies', () async {
      final command = Command0<int>(() async => Result<int>.ok(1));
      await command.execute();
      expect(command.result, isNotNull);

      var notified = false;
      command.addListener(() => notified = true);
      command.clearResult();

      expect(command.result, isNull);
      expect(command.completed, isFalse);
      expect(command.error, isFalse);
      expect(notified, isTrue);
    });
  });

  group('Command1', () {
    test('forwards the argument to the action', () async {
      String? seen;
      final command = Command1<String, String>((argument) async {
        seen = argument;
        return Result<String>.ok('done');
      });

      await command.execute('hello');

      expect(seen, 'hello');
      expect((command.result! as Ok<String>).value, 'done');
    });

    test(
      'applies the same concurrency guard as the no-argument form',
      () async {
        final gate = Completer<Result<int>>();
        var calls = 0;
        final command = Command1<int, String>((_) {
          calls++;
          return gate.future;
        });

        final first = command.execute('a');
        expect(command.running, isTrue);

        await command.execute('b');
        expect(calls, 1);

        gate.complete(Result<int>.ok(1));
        await first;
        expect(calls, 1);
      },
    );
  });
}
