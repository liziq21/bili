import 'package:material_ui/material_ui.dart';

import '../../l10n/localization_file/app_localizations.dart';
import '../../l10n/localization_file/app_localizations_en.dart';

class const NotFoundScreen({
  super.key,
  required final String uri,
  required final String path,
}) extends StatelessWidget {
  static final RegExp _controlChars = RegExp(r'[\x00-\x1F\x7F]');

  /// Sanitizes raw URI input by stripping control characters and masking
  /// sensitive query parameter values to prevent credential exposure in 404 UI.
  static String sanitizeUriString(String input) {
    var sanitized = input.replaceAll(_controlChars, '').trim();
    final parsed = Uri.tryParse(sanitized);
    if (parsed != null && parsed.hasQuery) {
      final maskedQueryParams = <String, String>{
        for (final key in parsed.queryParameters.keys) key: 'REDACTED',
      };
      sanitized = parsed.replace(queryParameters: maskedQueryParams).toString();
    }
    return sanitized;
  }

  @override
  Widget build(BuildContext context) {
    // 部分 golden 与 widget 测试直接 pump 本页、未注册 l10n delegate；此时
    // 回退到模板语言的生成实现，避免在页面里再复制一份文案。
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEn();
    final sanitizedUri = sanitizeUriString(uri);
    final sanitizedPath = path.replaceAll(_controlChars, '');
    return Scaffold(
      appBar: AppBar(title: Text(l10n.notFoundTitle)),
      body: Center(child: Text(l10n.notFoundBody(sanitizedUri, sanitizedPath))),
    );
  }
}
