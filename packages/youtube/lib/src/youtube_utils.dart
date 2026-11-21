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

final RegExp _videoIdPattern = RegExp(r'^[A-Za-z0-9_-]+$');

/// Builds the public thumbnail URL for a [videoId].
///
/// The `i.ytimg.com/vi/<id>/hqdefault.jpg` shape is the one YouTube itself
/// returns in `player.videoDetails.thumbnail`, so it needs no extra request.
/// Returns null when the ID is empty or contains characters that do not belong
/// in a YouTube video ID, which keeps a malformed ID from becoming a URL path.
String? buildYoutubeThumbnailUrl(String? videoId) {
  if (videoId == null) return null;
  final sanitized = videoId.replaceAll(_controlChars, '').trim();
  if (sanitized.isEmpty || !_videoIdPattern.hasMatch(sanitized)) return null;
  return 'https://i.ytimg.com/vi/$sanitized/hqdefault.jpg';
}

/// Parses a YouTube display count such as `12,825,676`, `5.9万次观看`,
/// `1.2M views`, or `34K` into an integer.
///
/// Returns null when no number is present. The suffix set covers the compact
/// forms YouTube uses in Chinese (`万`, `亿`) and English (`K`, `M`, `B`).
int? parseYoutubeCount(String? text) {
  if (text == null) return null;
  final normalized = text
      .toLowerCase()
      .replaceAll(',', '')
      .replaceAll(RegExp(r'\s+'), '');
  if (normalized.isEmpty) return null;

  final match = RegExp(r'(\d+(?:\.\d+)?)(万|亿|k|m|b)?').firstMatch(normalized);
  if (match == null) return null;
  final value = double.tryParse(match.group(1)!);
  if (value == null) return null;

  final multiplier = switch (match.group(2)) {
    '万' => 1e4,
    '亿' => 1e8,
    'k' => 1e3,
    'm' => 1e6,
    'b' => 1e9,
    _ => 1.0,
  };
  return (value * multiplier).round();
}

/// Parses YouTube's relative timestamp text into an absolute [DateTime].
///
/// Handles the English (`3 months ago`) and Chinese (`3个月前`) forms plus the
/// ISO date some responses carry. Returns null when the text carries no
/// recognisable unit; callers treat that as "unknown" rather than guessing.
DateTime? parseYoutubeRelativeDate(String? text) {
  if (text == null) return null;
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;

  final direct = DateTime.tryParse(trimmed);
  if (direct != null) return direct;

  final lower = trimmed.toLowerCase();
  if (lower.contains('just now') || trimmed.contains('刚刚')) {
    return DateTime.now();
  }

  final match = RegExp(r'(\d+)').firstMatch(lower);
  if (match == null) return null;
  final amount = int.tryParse(match.group(1)!);
  if (amount == null) return null;

  final now = DateTime.now();
  if (lower.contains('second') || trimmed.contains('秒')) {
    return now.subtract(Duration(seconds: amount));
  }
  if (lower.contains('minute') || trimmed.contains('分钟')) {
    return now.subtract(Duration(minutes: amount));
  }
  if (lower.contains('hour') || trimmed.contains('小时')) {
    return now.subtract(Duration(hours: amount));
  }
  if (lower.contains('day') || trimmed.contains('天')) {
    return now.subtract(Duration(days: amount));
  }
  if (lower.contains('week') ||
      trimmed.contains('周') ||
      trimmed.contains('星期')) {
    return now.subtract(Duration(days: amount * 7));
  }
  if (lower.contains('month') ||
      trimmed.contains('个月') ||
      trimmed.contains('月')) {
    return now.subtract(Duration(days: amount * 30));
  }
  if (lower.contains('year') || trimmed.contains('年')) {
    return now.subtract(Duration(days: amount * 365));
  }
  return null;
}
