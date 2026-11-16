import 'package:data/data.dart';
import 'package:ypi/ypi.dart';

import 'search_filter.dart';

/// A YouTube search sort order.
///
/// [label] is the stable identifier of the option, not user-facing copy: the
/// localized text lives in `youtube_<locale>.arb` and is read through
/// `labelWithL10n` / `localizedLabel`. [apiValue] is the value the InnerTube
/// request carries.
enum YoutubeSearchSort(@override final String label, final String apiValue)
    implements SortOption {
  relevance('relevance', 'relevance'),
  uploadDate('uploadDate', 'uploadDate'),
  viewCount('viewCount', 'viewCount'),
  rating('rating', 'rating');

  /// The protobuf varint written at search-params field 2. Relevance (0) is
  /// omitted by the encoder, which is why the default request has no sort.
  int get sortValue => index;

  @override
  String get value => apiValue;

  @override
  Map<String, String> toQueryParams() => {'sort': value};
}

/// The pure InnerTube request parameters for the YouTube video search tab.
///
/// Translating neutral `data` filters into these raw values is a data-layer
/// concern: `ypi` only receives an opaque, already-encoded params string.
typedef YoutubeVideoSearchParams = ({
  int? sort,
  int? uploadDate,
  int? duration,
  Set<int> features,
});

extension YoutubeVideoSearchParamsX on YoutubeVideoSearchParams {
  String encode() => YoutubeSearchParams.encode(
    sort: sort,
    contentType: YoutubeContentTypeFilterOption.video.contentType,
    uploadDate: uploadDate,
    duration: duration,
    features: features,
  );
}
