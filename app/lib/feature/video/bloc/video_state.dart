part of 'video_bloc.dart';

class VideoState extends Equatable {
  const VideoState({
    this.isLoading = false,
    this.error,
    this.videoDetail,
  });

  final bool isLoading;
  final String? error;
  final VideoDetail? videoDetail;

  VideoState copyWith({
    bool? isLoading,
    String? error,
    VideoDetail? videoDetail,
  }) {
    return VideoState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      videoDetail: videoDetail ?? this.videoDetail,
    );
  }

  @override
  List<Object?> get props => [isLoading, error, videoDetail];
}
