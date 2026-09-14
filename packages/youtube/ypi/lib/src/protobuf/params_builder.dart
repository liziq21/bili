import '../model/yt_search_filter.dart';
import '../model/yt_search_sort.dart';
import 'yt_protobuf_encoder.dart';

final class YoutubeParamsBuilder {
  YoutubeParamsBuilder({
    this.sort = YoutubeSearchSort.relevance,
    this.uploadDate,
    this.contentType,
    this.duration,
    Set<YoutubeFeatureFilter>? features,
  }) : features = features ?? {};

  YoutubeSearchSort sort;
  YoutubeUploadDateFilter? uploadDate;
  YoutubeContentTypeFilter? contentType;
  YoutubeDurationFilter? duration;
  Set<YoutubeFeatureFilter> features;

  YoutubeParamsBuilder setSort(YoutubeSearchSort sort) {
    this.sort = sort;
    return this;
  }

  YoutubeParamsBuilder setUploadDate(YoutubeUploadDateFilter? uploadDate) {
    this.uploadDate = uploadDate;
    return this;
  }

  YoutubeParamsBuilder setContentType(YoutubeContentTypeFilter? contentType) {
    this.contentType = contentType;
    return this;
  }

  YoutubeParamsBuilder setDuration(YoutubeDurationFilter? duration) {
    this.duration = duration;
    return this;
  }

  YoutubeParamsBuilder addFeature(YoutubeFeatureFilter feature) {
    features.add(feature);
    return this;
  }

  YoutubeParamsBuilder removeFeature(YoutubeFeatureFilter feature) {
    features.remove(feature);
    return this;
  }

  String build() {
    return YoutubeProtobufEncoder.encodeSearchParams(
      sort: sort,
      uploadDate: uploadDate,
      contentType: contentType,
      duration: duration,
      features: features,
    );
  }
}
