part of 'video_bloc.dart';

class const VideoState({
  final bool isLoading = false,
  final String? error,
  final VideoDetail? videoDetail,
}) extends Equatable {
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
