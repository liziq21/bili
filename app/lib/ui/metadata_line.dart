// 渲染对象的字段要在 `updateRenderObject` 里可变地更新，写不成主构造函数的
// final 字段；这三条规则只适用于纯赋值式构造。
// ignore_for_file: prefer_initializing_formals, unnecessary_type_name_in_constructor, use_primary_constructors

import 'package:flutter/semantics.dart' show SemanticsConfiguration;
import 'package:material_ui/material_ui.dart';

/// 一行元信息里的一个字段。
///
/// [priority] 越高越重要。一行放不下时，[MetadataLine] 丢掉分值最低的字段，
/// 而不是把整串文字交给省略号：多个字段拼成一个字符串再截断，被吃掉的总是
/// 排在末尾的那几个，而它们常常正是读者最需要的数字（#682）。
class const MetadataPart(final String text, {final int priority = 0});

/// 单行元信息：字段按给定顺序排列，宽度不够时按 [MetadataPart.priority]
/// 从低到高逐个丢弃，直到剩下的字段能完整排下。
///
/// 保留的字段拼成一行交给省略号兜底——只剩一个字段仍放不下时（例如卡片宽度
/// 小于一个播放量），那一个字段本身才允许被截断，而不是连带前面已经排下的
/// 字段一起消失。
///
/// 之所以不用 `LayoutBuilder` 取宽度：这些卡片也会出现在按固有尺寸测量的
/// 容器里（golden 用例的 `Table`、`IntrinsicHeight`），而 `LayoutBuilder`
/// 无法回答固有尺寸查询，会直接抛异常。这里改用自定义渲染对象，在
/// [RenderBox.performLayout] 里量宽度，固有尺寸按「全部字段」回答——固有
/// 尺寸只用于分配空间，给上界即可。
class const MetadataLine({
  required final List<MetadataPart> parts,
  required final String separator,
  required final TextStyle style,
  super.key,
}) extends LeafRenderObjectWidget {
  @override
  RenderMetadataLine createRenderObject(BuildContext context) =>
      RenderMetadataLine(
        parts: parts,
        separator: separator,
        // 卡片里的 `Text` 会把自身样式合并到环境样式上，量测必须用同一份
        // 结果，否则继承来的字体、字距与行高会让预算偏小。
        style: DefaultTextStyle.of(context).style.merge(style),
        textScaler: MediaQuery.textScalerOf(context),
        textDirection: Directionality.of(context),
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderMetadataLine renderObject,
  ) {
    renderObject
      ..parts = parts
      ..separator = separator
      ..style = DefaultTextStyle.of(context).style.merge(style)
      ..textScaler = MediaQuery.textScalerOf(context)
      ..textDirection = Directionality.of(context);
  }
}

/// [MetadataLine] 的渲染对象：先按优先级挑出放得下的字段，再按一行排版。
class RenderMetadataLine extends RenderBox {
  RenderMetadataLine({
    required List<MetadataPart> parts,
    required String separator,
    required TextStyle style,
    required TextScaler textScaler,
    required TextDirection textDirection,
  }) : _visible = _withoutEmpty(parts),
       _separator = separator,
       _style = style,
       _textScaler = textScaler,
       _textDirection = textDirection;

  static List<MetadataPart> _withoutEmpty(List<MetadataPart> parts) =>
      parts.where((part) => part.text.isNotEmpty).toList(growable: false);

  // lib 里不许出现非 ASCII 字面量（见 hardcoded_copy_test），所以省略号按码位
  // 构造，和 `app/lib/utils/text.dart` 的做法一致。
  static final String _ellipsis = String.fromCharCode(0x2026);

  /// 只用于最终排版与绘制；固有尺寸和逐字段量测都走 [_scratch]，否则一次
  /// 固有尺寸查询会把已经排好的这一行换成「全部字段」，下一次 paint 就画错。
  final TextPainter _painter = TextPainter(maxLines: 1);
  final TextPainter _scratch = TextPainter(maxLines: 1);

  List<MetadataPart> _visible;
  String _rendered = '';
  String _separator;
  TextStyle _style;
  TextScaler _textScaler;
  TextDirection _textDirection;

  set parts(List<MetadataPart> value) {
    _visible = _withoutEmpty(value);
    markNeedsLayout();
  }

  set separator(String value) {
    if (_separator == value) return;
    _separator = value;
    markNeedsLayout();
  }

  set style(TextStyle value) {
    if (_style == value) return;
    _style = value;
    markNeedsLayout();
  }

  set textScaler(TextScaler value) {
    if (_textScaler == value) return;
    _textScaler = value;
    markNeedsLayout();
  }

  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsLayout();
  }

  /// 能完整排进 [maxWidth] 的字段子集，保持原有顺序。
  List<MetadataPart> _fit(double maxWidth) {
    if (_visible.length < 2 || !maxWidth.isFinite) return _visible;

    final kept = [..._visible];
    double widthOf(List<MetadataPart> fields) =>
        _measure(fields.map((part) => part.text).join(_separator));

    while (kept.length > 1 && widthOf(kept) > maxWidth) {
      // 同分时丢靠后的字段：阅读顺序上靠前的字段更重要。
      var dropIndex = 0;
      for (var i = 1; i < kept.length; i++) {
        if (kept[i].priority <= kept[dropIndex].priority) dropIndex = i;
      }
      kept.removeAt(dropIndex);
    }
    return kept;
  }

  String _join(List<MetadataPart> fields) =>
      fields.map((part) => part.text).join(_separator);

  void _layout(TextPainter painter, String text, {required double maxWidth}) {
    painter
      ..text = TextSpan(text: text, style: _style)
      ..textDirection = _textDirection
      ..textScaler = _textScaler
      ..ellipsis = _ellipsis
      ..layout(maxWidth: maxWidth);
  }

  double _measure(String text) {
    _layout(_scratch, text, maxWidth: double.infinity);
    return _scratch.width;
  }

  /// 实际排进这一行的文字：宽度不够时它是丢掉低分字段后的结果。
  @visibleForTesting
  String get renderedText => _rendered;

  /// 这一行的文字是否被省略号截断（丢字段之后仍放不下才会发生）。
  @visibleForTesting
  bool get textWasClipped => _painter.didExceedMaxLines;

  @override
  void performLayout() {
    _rendered = _join(_fit(constraints.maxWidth));
    _layout(
      _painter,
      _rendered,
      maxWidth: constraints.hasBoundedWidth
          ? constraints.maxWidth
          : double.infinity,
    );
    size = constraints.constrain(Size(_painter.width, _painter.height));
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final painter =
        TextPainter(
          text: TextSpan(
            text: _join(_fit(constraints.maxWidth)),
            style: _style,
          ),
          textDirection: _textDirection,
          textScaler: _textScaler,
          maxLines: 1,
          ellipsis: _ellipsis,
        )..layout(
          maxWidth: constraints.hasBoundedWidth
              ? constraints.maxWidth
              : double.infinity,
        );
    final size = constraints.constrain(Size(painter.width, painter.height));
    painter.dispose();
    return size;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    final visible = _visible;
    if (visible.isEmpty) return 0;
    // 一行至少要有最高分那个字段的宽度，否则它也只能显示成省略号。
    final best = visible.reduce((a, b) => b.priority > a.priority ? b : a);
    return _measure(best.text);
  }

  @override
  double computeMaxIntrinsicWidth(double height) => _measure(_join(_visible));

  @override
  double computeMinIntrinsicHeight(double width) => _lineHeight();

  @override
  double computeMaxIntrinsicHeight(double width) => _lineHeight();

  double _lineHeight() {
    _layout(_scratch, _ellipsis, maxWidth: double.infinity);
    return _scratch.height;
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    _layout(_scratch, _join(_visible), maxWidth: double.infinity);
    return _scratch.computeDistanceToActualBaseline(baseline);
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    _painter.paint(context.canvas, offset);
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    // 屏幕阅读器读完整的字段：丢字段只是宽度不够时的视觉取舍。
    config.label = _join(_visible);
    config.textDirection = _textDirection;
  }

  @override
  void dispose() {
    _painter.dispose();
    _scratch.dispose();
    super.dispose();
  }
}
