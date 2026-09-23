import 'package:app/styles/styles.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses standard animation durations by default', () {
    final times = AppStyle().times;

    expect(times.fast, const Duration(milliseconds: 300));
    expect(times.med, const Duration(milliseconds: 600));
    expect(times.slow, const Duration(milliseconds: 900));
    expect(times.extraSlow, const Duration(milliseconds: 1300));
    expect(times.pageTransition, const Duration(milliseconds: 200));
  });

  test('uses minimal animation durations when animations are disabled', () {
    final times = AppStyle(disableAnimations: true).times;

    expect(times.fast, const Duration(milliseconds: 1));
    expect(times.med, const Duration(milliseconds: 1));
    expect(times.slow, const Duration(milliseconds: 1));
    expect(times.extraSlow, const Duration(milliseconds: 1));
    expect(times.pageTransition, const Duration(milliseconds: 1));
  });
}
