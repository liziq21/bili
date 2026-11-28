import 'package:material_ui/material_ui.dart';

import '../../l10n/localization_file/app_localizations.dart';

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
    // 这些 golden 与少量 widget 测试直接 pump 本页、未注册 l10n delegate；
    // l10n 为空时回退到英文，保证 404 页在最小树里也能渲染。
    final l10n = AppLocalizations.of(context);
    final sanitizedUri = sanitizeUriString(uri);
    final sanitizedPath = path.replaceAll(_controlChars, '');
    return Scaffold(
      appBar: AppBar(title: Text(l10n?.notFoundTitle ?? 'Page Not Found')),
      body: Center(
        child: Text(
          l10n?.notFoundBody(sanitizedUri, sanitizedPath) ??
              "Can't find a page for: $sanitizedUri \n Path: $sanitizedPath",
        ),
      ),
    );
  }
}
