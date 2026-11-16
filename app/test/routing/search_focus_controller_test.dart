import 'package:app/routing/search_focus_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// [SearchFocusController] 单元测试：验证聚焦注册、触发与注销语义。
void main() {
  group('SearchFocusController', () {
    test('requestFocus does not throw when no callback registered', () {
      final controller = SearchFocusController();
      addTearDown(controller.dispose);

      expect(controller.requestFocus, returnsNormally);
    });

    test('requestFocus triggers registered callback exactly once', () {
      final controller = SearchFocusController();
      addTearDown(controller.dispose);

      var callCount = 0;
      void callback() => callCount++;

      controller.register(callback);
      controller.requestFocus();

      expect(callCount, 1);
    });

    test('registering null unregisters the callback', () {
      final controller = SearchFocusController();
      addTearDown(controller.dispose);

      var callCount = 0;
      void callback() => callCount++;

      controller.register(callback);
      controller.requestFocus();
      expect(callCount, 1);

      controller.register(null);
      controller.requestFocus();

      // After unregistering, calling requestFocus should not invoke the old callback.
      expect(callCount, 1);
    });

    test('multiple register calls replace the callback', () {
      final controller = SearchFocusController();
      addTearDown(controller.dispose);

      var firstCalls = 0;
      var secondCalls = 0;
      void first() => firstCalls++;
      void second() => secondCalls++;

      controller.register(first);
      controller.register(second);
      controller.requestFocus();

      // Only the second callback should be called.
      expect(firstCalls, 0);
      expect(secondCalls, 1);
    });

    test('dispose does not throw', () {
      final controller = SearchFocusController();
      expect(controller.dispose, returnsNormally);
    });
  });
}
