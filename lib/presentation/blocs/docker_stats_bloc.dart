import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/docker_container.dart';
import '../../domain/usecases/get_containers.dart';
import '../../domain/usecases/get_container_stats.dart';

part 'docker_stats_event.dart';
part 'docker_stats_state.dart';

class DockerStatsBloc extends Bloc<DockerStatsEvent, DockerStatsState> {
  final GetContainers getContainers;
  final GetContainerStats getContainerStats;

  Map<String, dynamic>? _lastStats;

  DockerStatsBloc({
    required this.getContainers,
    required this.getContainerStats,
  }) : super(DockerStatsInitial()) {
    on<LoadContainers>(_onLoadContainers);
    on<LoadContainerStats>(_onLoadContainerStats);
    on<UpdateContainerStats>(_onUpdateContainerStats);
  }

  Future<void> _onLoadContainers(
    LoadContainers event,
    Emitter<DockerStatsState> emit,
  ) async {
    emit(DockerStatsLoading());
    try {
      final containers = await getContainers();
      emit(DockerStatsLoaded(containers: containers));
    } catch (e) {
      emit(DockerStatsError(message: e.toString()));
    }
  }

  Future<void> _onLoadContainerStats(
    LoadContainerStats event,
    Emitter<DockerStatsState> emit,
  ) async {
    emit(ContainerStatsLoading());
    try {
      final stats = await getContainerStats(event.containerId);
      _lastStats = stats;
      emit(ContainerStatsLoaded(stats: stats));
    } catch (e) {
      emit(DockerStatsError(message: e.toString()));
    }
  }

  Future<void> _onUpdateContainerStats(
    UpdateContainerStats event,
    Emitter<DockerStatsState> emit,
  ) async {
    // Only emit updating state if we have previous stats
    if (_lastStats != null) {
      emit(ContainerStatsUpdating(lastStats: _lastStats!));
    }
    try {
      final stats = await getContainerStats(event.containerId);
      _lastStats = stats;
      emit(ContainerStatsLoaded(stats: stats));
    } catch (e) {
      // If update fails, keep the last stats
      if (_lastStats != null) {
        emit(ContainerStatsLoaded(stats: _lastStats!));
      } else {
        emit(DockerStatsError(message: e.toString()));
      }
    }
  }
}