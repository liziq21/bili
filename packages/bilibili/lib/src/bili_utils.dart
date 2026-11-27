import 'uri_extensions.dart';

/// Non-printable ASCII control characters.
final RegExp _controlChars = RegExp(r'[\x00-\x1F\x7F]');

/// ASCII 控制字符，加上会把 BV id 从路径段里「放出去」的 URI 分隔符：
/// `?` 起查询串、`#` 起片段、`/` 与 `\` 能把剩余部分挪到别的路径段或主机。
final RegExp _unsafeBvidChars = RegExp(r'[\x00-\x1F\x7F?#/\\]');

/// Standardizes and secures Bilibili media/asset URLs into valid HTTPS URLs.
///
/// Trims surrounding whitespace, matches the scheme case-insensitively, and
/// handles scheme-relative (`//`), unencrypted (`http://`), already secure
/// (`https://`), and empty/null values without producing corrupted scheme
/// prefixes (`https:https://`). Anything that is not an http(s) URL returns
/// null, so `ftp:`, `data:`, `javascript:`, and relative paths never reach an
/// image or player request.
String? normalizeBiliUrl(String? url) {
  final trimmed = url?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  if (trimmed.startsWith('//')) return 'https:$trimmed';
  final lower = trimmed.toLowerCase();
  if (lower.startsWith('https://')) return 'https://${trimmed.substring(8)}';
  if (lower.startsWith('http://')) return 'https://${trimmed.substring(7)}';
  return null;
}

/// Constructs a secure Bilibili video watch URL from a BV id.
///
/// Strips non-printable ASCII control characters and the URI delimiters
/// (`?`, `#`, `/`, `\\`) and trims whitespace, so the id stays one path segment
/// of `www.bilibili.com` whatever the upstream feed put in it.
/// A well-formed BV id contains none of these, so valid ids are unaffected.
String buildBiliWatchUrl(String bvid) {
  final sanitizedBvid = bvid.replaceAll(_unsafeBvidChars, '').trim();
  return 'https://www.bilibili.com/video/$sanitizedBvid';
}

class BiliUtils() {
  /// 从 URI 中提取并构建路由路径
  ///
  /// 支持的 URI 格式：
  /// - HTTP/HTTPS: https://live.bilibili.com/xxx, https://search.bilibili.com/xxx
  /// - Bilibili Scheme: bilibili://live/xxx, bilibili://search/xxx
  ///
  /// 返回 null 如果 URI 格式不支持或无效
  static String? getRoutePath(Uri uri) {
    if (uri.host.isEmpty) return null;

    final path = _extractPath(uri);

    if (path == null) return null;

    return _buildRouteUri(path, uri);
  }

  static String? _extractPath(Uri uri) {
    if (uri.isHTTPScheme) {
      return _extractHttpPath(uri);
    } else if (uri.isBilibiiScheme) {
      return _extractBilibiliSchemePath(uri);
    }

    return null;
  }

  static String? _extractHttpPath(Uri uri) {
    final secondLevelDomain = uri.secondLevelDomain;
    if (secondLevelDomain != null && _isSupportedDomain(secondLevelDomain)) {
      return '/$secondLevelDomain${uri.path}';
    }
    return null;
  }

  static String? _extractBilibiliSchemePath(Uri uri) {
    final uriString = uri.toString();
    if (uriString.startsWith('bilibili:///')) {
      return null;
    }
    return '/${uri.host}${uri.path}';
  }

  static bool _isSupportedDomain(String domain) {
    return /*domain == Routes.liveRelative ||
           domain == Routes.searchRelative ||
           domain == Routes.spaceRelative*/ false;
  }

  static String _buildRouteUri(String path, Uri uri) {
    final sanitizedPath = path.replaceAll(_controlChars, '');
    final sanitizedQueryParams = uri.queryParametersAll.isEmpty
        ? null
        : uri.queryParametersAll.map(
            (key, values) => MapEntry(
              key.replaceAll(_controlChars, ''),
              values.map((v) => v.replaceAll(_controlChars, '')).toList(),
            ),
          );
    final sanitizedFragment = uri.fragment.isEmpty
        ? null
        : uri.fragment.replaceAll(_controlChars, '');

    return Uri(
      path: sanitizedPath,
      queryParameters: sanitizedQueryParams,
      fragment: sanitizedFragment,
    ).toString();
  }
}
