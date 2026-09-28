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
      ('accentText 压 surface', Contrast.ratio(light.accentText, surface)),
      (
        'onAccentFill 压 accentFill',
        Contrast.ratio(light.onAccentFill, light.accentFill),
      ),
      ('onSurface 压 surface', Contrast.ratio(scheme.onSurface, surface)),
      (
        'onSurfaceVariant 压 surface',
        Contrast.ratio(scheme.onSurfaceVariant, surface),
      ),
    ];
    for (final (label, r) in pairs) {
      expect(
        r,
        greaterThanOrEqualTo(Contrast.aaText),
        reason: '亮 $label 实际 ${r.toStringAsFixed(2)}:1',
      );
    }
  });

  test('light palette clears WCAG AA on all graphic roles (≥ 3.0:1)', () {
    final scheme = appThemeData(light).colorScheme;
    final surface = light.surface;
    final pairs = [
      ('accentFill 压 surface', Contrast.ratio(light.accentFill, surface)),
      ('primary 压 surface', Contrast.ratio(scheme.primary, surface)),
      ('secondary 压 surface', Contrast.ratio(scheme.secondary, surface)),
      ('outline 压 surface', Contrast.ratio(scheme.outline, surface)),
    ];
    for (final (label, r) in pairs) {
      expect(
        r,
        greaterThanOrEqualTo(Contrast.aaNonText),
        reason: '亮 $label 实际 ${r.toStringAsFixed(2)}:1',
      );
    }
  });

  test(
    'accentText is darker than accentFill, so text clears what graphics cannot',
    () {
      // R2.1 分档的回归守卫：两个角色同值时，accentFill 的 3.0:1 门槛会把
      // 只有 4.0:1 的值放行，文字档就没人管了。此处锁住「亮色下 accentText
      // 必须比 accentFill 深」——分档一旦被合并，这条先于对比度断言报错。
      expect(
        light.accentText.computeLuminance(),
        lessThan(light.accentFill.computeLuminance()),
        reason:
            '亮色 accentText ${light.accentText.toARGB32()} 须深于 '
            'accentFill ${light.accentFill.toARGB32()}',
      );
      // 暗色下 accent 本身 8.68:1，两档同值是有意的。
      expect(dark.accentText, dark.accentFill);
    },
  );

  test('dark palette clears WCAG AA on all text roles (≥ 4.5:1)', () {
    final scheme = appThemeData(dark).colorScheme;
    final surface = dark.surface;
    final pairs = [
      ('accentText 压 surface', Contrast.ratio(dark.accentText, surface)),
      (
        'onAccentFill 压 accentFill',
        Contrast.ratio(dark.onAccentFill, dark.accentFill),
      ),
      ('onSurface 压 surface', Contrast.ratio(scheme.onSurface, surface)),
      (
        'onSurfaceVariant 压 surface',
        Contrast.ratio(scheme.onSurfaceVariant, surface),
      ),
    ];
    for (final (label, r) in pairs) {
      expect(
        r,
        greaterThanOrEqualTo(Contrast.aaText),
        reason: '暗 $label 实际 ${r.toStringAsFixed(2)}:1',
      );
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
      expect(
        r,
        greaterThanOrEqualTo(Contrast.aaNonText),
        reason: '暗 $label 实际 ${r.toStringAsFixed(2)}:1',
      );
    }
  });

  test(
    'scrim carries a light foreground above WCAG AA in both brightnesses',
    () {
      for (final (name, c) in [('light', light), ('dark', dark)]) {
        final ratio = Contrast.ratio(c.onScrim, c.scrim);
        expect(
          ratio,
          greaterThanOrEqualTo(Contrast.aaText),
          reason: '$name onScrim 压 scrim 实际 ${ratio.toStringAsFixed(2)}:1',
        );
      }
    },
  );

  test('accentText is recomputed for a surface the brand value cannot carry', () {
    // `BrandPalette.fromScheme` 的保证：accentText 压**它将要用的那个** surface
    // 达 4.5:1。系统色板不受我们控制，若它给的 primary/surface 组合让品牌
    // accentText 压不住（这里故意给亮色标记 + 深色底的不匹配组合），必须
    // 重算而不是沿用。
    //
    // 说明范围：对「亮度标记与底色深浅一致」的正常系统色板，沿用品牌
    // accentText 本就够（暗色 #EFA97C 压深底 8.68:1、亮色 #9D4E1A 压近白底
    // 5.94:1），重算是防御性的；本条钉的是那条防御确实生效。
    final base = BrandPalette.of(Brightness.light);
    final mismatched = base.scheme.copyWith(surface: const Color(0xFF141218));

    // 前提：不匹配时品牌值确实不达标，否则本测试证明不了任何东西。
    expect(
      Contrast.ratio(base.accentText, mismatched.surface),
      lessThan(Contrast.aaText),
      reason: '探针前提：品牌 accentText 压该底色应不达标',
    );

    final derived = BrandPalette.fromScheme(mismatched, base: base);
    expect(
      Contrast.ratio(derived.accentText, mismatched.surface),
      greaterThanOrEqualTo(Contrast.aaText),
      reason: '重算后实际 '
          '${Contrast.ratio(derived.accentText, mismatched.surface).toStringAsFixed(2)}:1',
    );
    // 其余角色照旧跟随/沿用：色板角色取新的，承载面角色取品牌的。
    expect(derived.scheme.primary, mismatched.primary);
    expect(derived.scrim, base.scrim);
    expect(derived.onSurfaceStrong, base.onSurfaceStrong);
  });
}
