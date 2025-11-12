part of 'docker_stats_bloc.dart';

abstract class DockerStatsState extends Equatable {
  const DockerStatsState();

  @override
  List<Object> get props => [];
}

class DockerStatsInitial extends DockerStatsState {}

class DockerStatsLoading extends DockerStatsState {}

class DockerStatsLoaded extends DockerStatsState {
  final List<DockerContainer> containers;

  const DockerStatsLoaded({required this.containers});

  @override
  List<Object> get props => [containers];
}

class ContainerStatsLoading extends DockerStatsState {}

class ContainerStatsLoaded extends DockerStatsState {
  final Map<String, dynamic> stats;

  const ContainerStatsLoaded({required this.stats});

  @override
  List<Object> get props => [stats];
}

class ContainerStatsUpdating extends DockerStatsState {
  final Map<String, dynamic> lastStats;

  const ContainerStatsUpdating({required this.lastStats});

  @override
  List<Object> get props => [lastStats];
}

class DockerStatsError extends DockerStatsState {
  final String message;

  const DockerStatsError({required this.message});

  @override
  List<Object> get props => [message];
}