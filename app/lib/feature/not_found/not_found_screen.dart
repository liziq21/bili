import 'package:material_ui/material_ui.dart';

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
    final sanitizedUri = sanitizeUriString(uri);
    final sanitizedPath = path.replaceAll(_controlChars, '');
    return Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Text(
          "Can't find a page for: $sanitizedUri \n Path: $sanitizedPath",
        ),
      ),
    );
  }
}
