import '../../../l10n/localization_file/app_localizations.dart';
import 'playback_error.dart';

/// 播放器错误类别 → 本地化标签。
///
/// 只有分类文案可以上屏：原始异常可能带签名 CDN 地址与时效参数。
String playbackErrorCategoryLabel(
  AppLocalizations? l10n,
  PlaybackErrorCategory category,
) => switch (category) {
  PlaybackErrorCategory.open =>
    l10n?.playbackErrorOpen ?? 'Stream failed to open',
  PlaybackErrorCategory.network =>
    l10n?.playbackErrorNetwork ?? 'Network error',
  PlaybackErrorCategory.decoder =>
    l10n?.playbackErrorDecoder ?? 'Decoder error',
  PlaybackErrorCategory.drm => l10n?.playbackErrorDrm ?? 'DRM error',
  PlaybackErrorCategory.authorization =>
    l10n?.playbackErrorAuthorization ?? 'Authorization error',
  PlaybackErrorCategory.unknown =>
    l10n?.playbackErrorUnknown ?? 'Unknown error',
};
