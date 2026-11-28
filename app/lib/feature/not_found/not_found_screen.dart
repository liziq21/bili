import 'package:material_ui/material_ui.dart';

import '../../l10n/localization_file/app_localizations.dart';

class const NotFoundScreen({
  super.key,
  required final String uri,
  required final String path,

  /// 由调用方从 [AppLocalizations] 取好后注入，页面自身不查 context，
  /// 这样直接 pump 本页的 golden / widget 测试无需装配 l10n delegate。
  required final AppLocalizations l10n,
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
    final sanitizedUri = sanitizeUriString(uri);
    final sanitizedPath = path.replaceAll(_controlChars, '');
    return Scaffold(
      appBar: AppBar(title: Text(l10n.notFoundTitle)),
      body: Center(child: Text(l10n.notFoundBody(sanitizedUri, sanitizedPath))),
    );
  }
}
