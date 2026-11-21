import 'dart:async';

import 'package:data/data.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../l10n/localization_file/app_localizations.dart';
import '../../../main.dart';
import '../../../routing/router.dart';

/// 描述文本中的片段类型。
enum DescriptionTokenType() {
  text,
  link,
  topic,
}

/// 描述文本切分后的一个片段。
@immutable
class const DescriptionToken({
  required final DescriptionTokenType type,
  required final String text,
}) with Equatable {
  @override
  List<Object?> get props => [type, text];
}

/// 站内链接只复用当前数据源的路由；数据源 ID 是应用层的稳定契约。
const _bilibiliSourceId = 'bilibili';

final _descriptionTokenPattern = RegExp(r'(https?://[^\s]+)|(#[^#\s]+#)');

/// URL 末尾常被标点或右括号包住，链接本身不应包含这些字符。
///
/// 用码位而不是字面量：`app/lib` 的硬编码文案护栏禁止非 ASCII 字符串字面量。
const _trailingPunctuation = <int>{
  0x2E, 0x2C, 0x3B, 0x3A, 0x21, 0x3F, 0x29, 0x5D, 0x7D, // . , ; : ! ? ) ] }
  0xFF0C, 0x3002, 0xFF1B, 0xFF1A, 0xFF01, 0xFF1F, 0xFF09, // ，。；：！？）
  0x300B, 0x300D, 0x300F, // 》」』
};

/// 把描述文本切分为普通文本、链接和话题三类片段。
///
/// 纯函数，便于单元测试；渲染层只负责把片段映射成 [TextSpan]。
List<DescriptionToken> tokenizeDescription(String text) {
  if (text.isEmpty) return const [];

  final tokens = <DescriptionToken>[];
  var cursor = 0;

  void addText(String value) {
    if (value.isEmpty) return;
    tokens.add(DescriptionToken(type: DescriptionTokenType.text, text: value));
  }

  for (final match in _descriptionTokenPattern.allMatches(text)) {
    addText(text.substring(cursor, match.start));

    var value = match.group(0)!;
    var trailing = '';
    if (!value.startsWith('#')) {
      final end = value.length;
      var trimmed = end;
      while (trimmed > 0 &&
          _trailingPunctuation.contains(value.codeUnitAt(trimmed - 1))) {
        trimmed--;
      }
      if (trimmed < end) {
        trailing = value.substring(trimmed);
        value = value.substring(0, trimmed);
      }
    }

    tokens.add(
      DescriptionToken(
        type: value.startsWith('#')
            ? DescriptionTokenType.topic
            : DescriptionTokenType.link,
        text: value,
      ),
    );
    addText(trailing);
    cursor = match.end;
  }

  addText(text.substring(cursor));
  return tokens;
}

/// 富文本描述：链接可点击、话题高亮，整段支持长按选择复制。
///
/// 链接点击行为保持只读：站内视频/空间链接直接复用应用路由跳转，
/// 其余链接复制到剪贴板并提示。项目当前没有外部浏览器依赖，因此不做
/// 系统浏览器拉起。
class const VideoDescriptionText({
  super.key,
  required final String text,
  required final bool isExpanded,
}) extends StatefulWidget {
  @override
  State<VideoDescriptionText> createState() => _VideoDescriptionTextState();
}

class _VideoDescriptionTextState() extends State<VideoDescriptionText> {
  final List<TapGestureRecognizer> _recognizers = [];
  List<InlineSpan> _spans = const [];
  String? _tokenizedText;
  Color? _linkColor;
  Color? _topicColor;

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  void _ensureSpans(Color linkColor, Color topicColor) {
    if (_tokenizedText == widget.text &&
        _linkColor == linkColor &&
        _topicColor == topicColor) {
      return;
    }

    _disposeRecognizers();
    _linkColor = linkColor;
    _topicColor = topicColor;
    _tokenizedText = widget.text;

    final spans = <InlineSpan>[];
    for (final token in tokenizeDescription(widget.text)) {
      switch (token.type) {
        case DescriptionTokenType.text:
          spans.add(TextSpan(text: token.text));
        case DescriptionTokenType.link:
          final recognizer = TapGestureRecognizer()
            ..onTap = () => _openLink(token.text);
          _recognizers.add(recognizer);
          spans.add(
            TextSpan(
              text: token.text,
              recognizer: recognizer,
              style: TextStyle(
                color: linkColor,
                decoration: TextDecoration.underline,
                decorationColor: linkColor,
              ),
            ),
          );
        case DescriptionTokenType.topic:
          spans.add(
            TextSpan(
              text: token.text,
              style: TextStyle(color: topicColor, fontWeight: FontWeight.w600),
            ),
          );
      }
    }
    _spans = spans;
  }

  void _openLink(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    final source = context.read<MediaSource?>()?.id;
    final isBilibiliLink =
        uri != null &&
        (uri.host == 'bilibili.com' || uri.host.endsWith('.bilibili.com'));

    // 只在当前数据源确实是 B 站时复用站内路由，避免把 BV 号交给 YouTube。
    if (isBilibiliLink && source == _bilibiliSourceId) {
      final bvId = RegExp(r'BV[0-9A-Za-z]+').firstMatch(uri.path);
      if (bvId != null) {
        context.navigateToVideo(bvId.group(0)!, source: source);
        return;
      }

      if (uri.host == 'space.bilibili.com' && uri.pathSegments.isNotEmpty) {
        final mid = uri.pathSegments.first;
        if (mid.isNotEmpty) {
          context.navigateToSpace(mid, source: source);
          return;
        }
      }
    }

    unawaited(Clipboard.setData(ClipboardData(text: rawUrl)));
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l10n = AppLocalizations.of(context);
    messenger?.showSnackBar(
      SnackBar(
        content: Text(l10n?.trackCopiedToClipboard ?? 'Copied to clipboard'),
        duration: $styles.times.fast,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final linkColor = $styles.colors.accentText;
    final topicColor = $styles.colors.secondary;
    _ensureSpans(linkColor, topicColor);

    return SelectionArea(
      child: Text.rich(
        TextSpan(children: _spans),
        maxLines: widget.isExpanded ? null : 2,
        overflow: widget.isExpanded
            ? TextOverflow.visible
            : TextOverflow.ellipsis,
        style: $styles.text.bodySmall.copyWith(
          color: $styles.colors.onSurface,
          height: 1.4,
        ),
      ),
    );
  }
}
