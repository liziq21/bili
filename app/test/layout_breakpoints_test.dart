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

    test('accounts for grid spacing before adding a column', () {
      final size = LayoutSize.fromWidth(1008);

      expect(size.feedColumnsFor(1007, spacing: 16), 3);
      expect(size.feedColumnsFor(1008, spacing: 16), 4);
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
      expect(
        LayoutSize.fromWidth(360).liveCardWidth(360),
        inInclusiveRange(200, 280),
      );
      expect(
        LayoutSize.fromWidth(768).liveCardWidth(768),
        inInclusiveRange(240, 320),
      );
    });

    test('packs whole cards and fills the width exactly', () {
      // 回归：#644 的裁切来自「按目标宽度切卡」——4 张 283px 的卡加上间距
      // 比可用宽度还宽，最右一张整体溢出。列数必须由可用宽度算出，且
      // columns * cardWidth + gaps 恰好等于可用宽度。
      for (final double width in [
        1280.0,
        1189.0,
        1000.0,
        768.0,
        400.0,
        300.0,
        180.0,
        120.0,
      ]) {
        const spacing = 16.0;
        final available = width - 32;
        final metrics = LayoutSize.fromWidth(width)
            .liveGridMetrics(available, spacing: spacing);
        expect(metrics.columns, greaterThanOrEqualTo(1));
        expect(
          metrics.columns * metrics.cardWidth + spacing * (metrics.columns - 1),
          moreOrLessEquals(available, epsilon: 0.01),
          reason: 'width $width',
        );
        expect(metrics.cardWidth, lessThanOrEqualTo(available));
      }
    });

    test('uses more columns on wider windows', () {
      double cardWidthAt(double width) =>
          LayoutSize.fromWidth(width)
              .liveGridMetrics(width - 32, spacing: 16)
              .cardWidth;
      int columnsAt(double width) =>
          LayoutSize.fromWidth(width)
              .liveGridMetrics(width - 32, spacing: 16)
              .columns;

      expect(columnsAt(1280), 4);
      expect(columnsAt(1000), 3);
      expect(columnsAt(360), 1);
      // 窄到放不下目标宽度时，卡片退让到可用宽度而不是溢出。
      expect(cardWidthAt(180), 148);
      expect(cardWidthAt(1280), lessThanOrEqualTo(320));
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
