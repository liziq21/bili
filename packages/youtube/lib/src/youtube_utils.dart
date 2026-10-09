final RegExp _controlChars = RegExp(r'[\x00-\x1F\x7F]');

/// Standardizes and secures YouTube media/asset URLs into valid HTTPS URLs.
///
/// Handles scheme-relative (`//`), unencrypted (`http://`), already secure (`https://`),
/// and empty/null values safely without producing corrupted scheme prefixes (`https:https://`).
String? normalizeYoutubeUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('//')) return 'https:$url';
  if (url.startsWith('http://')) return 'https://${url.substring(7)}';
  return url;
}

/// Builds a sanitized YouTube video watch URL from a [videoId].
///
/// Strips ASCII control characters to prevent parameter or header injection.
/// Returns an empty string if [videoId] is null, empty, or consists only of control characters.
String buildYoutubeWatchUrl(String? videoId) {
  if (videoId == null || videoId.isEmpty) return '';
  final sanitized = videoId.replaceAll(_controlChars, '').trim();
  if (sanitized.isEmpty) return '';
  return 'https://www.youtube.com/watch?v=$sanitized';
}
