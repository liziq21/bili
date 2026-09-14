part of 'home_bloc.dart';

@immutable
class HomeState extends Equatable {
  const HomeState({
    this.serviceSource = ServiceSource.bilibili,
    this.isLoading = false,
  });

  final ServiceSource serviceSource;
  final bool isLoading;

  HomeState copyWith({ServiceSource? serviceSource, bool? isLoading}) {
    return HomeState(
      serviceSource: serviceSource ?? this.serviceSource,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [serviceSource, isLoading];
}
