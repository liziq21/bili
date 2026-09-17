import 'yt_protobuf_encoder.dart';

final class YoutubeParamsBuilder {
  YoutubeParamsBuilder({
    this.sort,
    this.uploadDate,
    this.contentType,
    this.duration,
    Set<int>? features,
  }) : features = features ?? {};

  int? sort;
  int? uploadDate;
  int? contentType;
  int? duration;
  Set<int> features;

  YoutubeParamsBuilder setSort(int? sort) {
    this.sort = sort;
    return this;
  }

  YoutubeParamsBuilder setUploadDate(int? uploadDate) {
    this.uploadDate = uploadDate;
    return this;
  }

  YoutubeParamsBuilder setContentType(int? contentType) {
    this.contentType = contentType;
    return this;
  }

  YoutubeParamsBuilder setDuration(int? duration) {
    this.duration = duration;
    return this;
  }

  YoutubeParamsBuilder addFeature(int featureFieldTag) {
    features.add(featureFieldTag);
    return this;
  }

  YoutubeParamsBuilder removeFeature(int featureFieldTag) {
    features.remove(featureFieldTag);
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
