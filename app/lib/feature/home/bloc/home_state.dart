part of 'home_bloc.dart';

@immutable
class HomeState extends Equatable {
  const HomeState({
    this.sourceId = 'bilibili',
    this.isLoading = false,
  });

  final String sourceId;
  final bool isLoading;

  HomeState copyWith({String? sourceId, bool? isLoading}) {
    return HomeState(
      sourceId: sourceId ?? this.sourceId,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [sourceId, isLoading];
}
