import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// WCAG 2.1 相对亮度与对比度计算。
///
/// 供调色与 G2 对比度测试使用，不参与渲染。
///
/// 公式与阈值来源：WCAG 2.1 §Relative luminance 与 §Contrast (minimum)，
/// <https://www.w3.org/TR/WCAG21/#dfn-relative-luminance>、
/// <https://www.w3.org/TR/WCAG21/#dfn-contrast-ratio>。
abstract final class Contrast() {
  /// sRGB 相对亮度，值域 `[0, 1]`。
  static double relativeLuminance(Color color) {
    double channel(double c8) => c8 <= 0.03928
        ? c8 / 12.92
        : math.pow((c8 + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * channel(color.r) +
        0.7152 * channel(color.g) +
        0.0722 * channel(color.b);
  }

  /// 对比度，值域 `[1, 21]`，与参数顺序无关。
  static double ratio(Color a, Color b) {
    final la = relativeLuminance(a);
    final lb = relativeLuminance(b);
    final lighter = math.max(la, lb);
    final darker = math.min(la, lb);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// 普通字号文本的 WCAG AA 门槛。
  static const double aaText = 4.5;

  /// 非文本内容（指示器、图形对象）与大文本的 WCAG AA 门槛。
  static const double aaNonText = 3.0;
}
