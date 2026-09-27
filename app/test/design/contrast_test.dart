import 'package:app/design/design.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// G2 对比度门禁（规范 §4/G2）。
///
/// 断言 [BrandPalette] 中所有前景/背景角色对在实际渲染中达到的 WCAG 对比度
/// 不低于规范约定的门槛：正文文字 ≥ [Contrast.aaText]，图形/指示器 ≥
/// [Contrast.aaNonText]。门槛与取值方案见品牌色板注释（P3 方案 B）。
void main() {
  final light = AppColors(BrandPalette.of(Brightness.light));
  final dark = AppColors(BrandPalette.of(Brightness.dark));

  test('light palette clears WCAG AA on all text roles (≥ 4.5:1)', () {
    final scheme = appThemeData(light).colorScheme;
    final surface = light.surface;
    final pairs = [
      ('onPrimary 压 primary', Contrast.ratio(scheme.onPrimary, scheme.primary)),
      ('onSurface 压 surface', Contrast.ratio(scheme.onSurface, surface)),
      ('onSurfaceVariant 压 surface', Contrast.ratio(scheme.onSurfaceVariant, surface)),
    ];
    for (final (label, r) in pairs) {
      expect(r, greaterThanOrEqualTo(Contrast.aaText), reason: '亮 $label 实际 ${r.toStringAsFixed(2)}:1');
    }
  });

  test('light palette clears WCAG AA on all graphic roles (≥ 3.0:1)', () {
    final scheme = appThemeData(light).colorScheme;
    final surface = light.surface;
    final pairs = [
      ('primary 压 surface', Contrast.ratio(scheme.primary, surface)),
      ('secondary 压 surface', Contrast.ratio(scheme.secondary, surface)),
      ('outline 压 surface', Contrast.ratio(scheme.outline, surface)),
    ];
    for (final (label, r) in pairs) {
      expect(r, greaterThanOrEqualTo(Contrast.aaNonText), reason: '亮 $label 实际 ${r.toStringAsFixed(2)}:1');
    }
  });

  test('dark palette clears WCAG AA on all text roles (≥ 4.5:1)', () {
    final scheme = appThemeData(dark).colorScheme;
    final surface = dark.surface;
    final pairs = [
      ('onPrimary 压 primary', Contrast.ratio(scheme.onPrimary, scheme.primary)),
      ('onSurface 压 surface', Contrast.ratio(scheme.onSurface, surface)),
      ('onSurfaceVariant 压 surface', Contrast.ratio(scheme.onSurfaceVariant, surface)),
    ];
    for (final (label, r) in pairs) {
      expect(r, greaterThanOrEqualTo(Contrast.aaText), reason: '暗 $label 实际 ${r.toStringAsFixed(2)}:1');
    }
  });

  test('dark palette clears WCAG AA on all graphic roles (≥ 3.0:1)', () {
    final scheme = appThemeData(dark).colorScheme;
    final surface = dark.surface;
    final pairs = [
      ('primary 压 surface', Contrast.ratio(scheme.primary, surface)),
      ('secondary 压 surface', Contrast.ratio(scheme.secondary, surface)),
      ('outline 压 surface', Contrast.ratio(scheme.outline, surface)),
    ];
    for (final (label, r) in pairs) {
      expect(r, greaterThanOrEqualTo(Contrast.aaNonText), reason: '暗 $label 实际 ${r.toStringAsFixed(2)}:1');
    }
  });

  test('scrim carries a light foreground above WCAG AA in both brightnesses', () {
    for (final (name, c) in [('light', light), ('dark', dark)]) {
      final ratio = Contrast.ratio(c.onScrim, c.scrim);
      expect(
        ratio,
        greaterThanOrEqualTo(Contrast.aaText),
        reason: '$name onScrim 压 scrim 实际 ${ratio.toStringAsFixed(2)}:1',
      );
    }
  });
}
