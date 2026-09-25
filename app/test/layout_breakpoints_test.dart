import 'package:app/ui/common/utils/layout_breakpoints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LayoutSize.feedColumnsFor', () {
    test('keeps the phone and tablet layouts unchanged', () {
      // Phones stay single column, tablets stay two columns.
      expect(LayoutSize.fromWidth(360).feedColumnsFor(360), 1);
      expect(LayoutSize.fromWidth(599).feedColumnsFor(599), 1);
      expect(LayoutSize.fromWidth(600).feedColumnsFor(600), 2);
      expect(LayoutSize.fromWidth(800).feedColumnsFor(800), 2);
    });

    test('gains columns as a desktop window gets wider', () {
      expect(LayoutSize.fromWidth(900).feedColumnsFor(900), 3);
      expect(LayoutSize.fromWidth(1280).feedColumnsFor(1280), 5);
      expect(LayoutSize.fromWidth(1920).feedColumnsFor(1920), 8);
    });

    test('never drops below the tier floor', () {
      // A narrow window must not fall back to zero columns.
      for (final double width in [320, 480, 640, 960, 1400, 2560]) {
        expect(
          LayoutSize.fromWidth(width).feedColumnsFor(width),
          greaterThanOrEqualTo(LayoutSize.fromWidth(width).feedColumns),
        );
      }
    });
  });

  group('LayoutSize.liveCardWidth', () {
    test('stays within the phone and tablet ranges', () {
      expect(LayoutSize.fromWidth(360).liveCardWidth(360), inInclusiveRange(200, 280));
      expect(LayoutSize.fromWidth(768).liveCardWidth(768), inInclusiveRange(240, 320));
    });

    test('does not grow without bound on wide desktop windows', () {
      // The expanded tier used to scale with the window width, which made a
      // single card grow past 350px on a 1280px window.
      for (final double width in [900, 1280, 1920, 2560, 3440]) {
        expect(
          LayoutSize.fromWidth(width).liveCardWidth(width),
          inInclusiveRange(240, 320),
        );
      }
    });
  });
}
