part of 'docker_stats_bloc.dart';

abstract class DockerStatsEvent extends Equatable {
  const DockerStatsEvent();

  @override
  List<Object> get props => [];
}

class LoadContainers extends DockerStatsEvent {}

class LoadContainerStats extends DockerStatsEvent {
  final String containerId;

  const LoadContainerStats(this.containerId);

  @override
  List<Object> get props => [containerId];
}

class UpdateContainerStats extends DockerStatsEvent {
  final String containerId;

  const UpdateContainerStats(this.containerId);

  @override
  List<Object> get props => [containerId];
}