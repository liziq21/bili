part of 'home_bloc.dart';

sealed class HomeEvent {}

class MonitorUserData extends HomeEvent {}

class ServiceSourceChanged(final String sourceId) extends HomeEvent;
