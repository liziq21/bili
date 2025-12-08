import 'routes.dart';
import 'uri_extensions.dart';

class BiliUtils {
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
    
    return _buildDecodedUri(path, uri);
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
    return domain == Routes.liveRelative ||
           domain == Routes.searchRelative ||
           domain == Routes.spaceRelative;
  }
  
  static String _buildDecodedUri(String path, Uri uri) =>
    Uri.decodeComponent(
      Uri(
        path: path,
        queryParameters: uri.queryParametersAll.isEmpty ? null : uri.queryParametersAll,
        fragment: uri.fragment.isEmpty ? null : uri.fragment,
      ).toString(),
    );
}
