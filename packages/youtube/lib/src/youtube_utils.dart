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
