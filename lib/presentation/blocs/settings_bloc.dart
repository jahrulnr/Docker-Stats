import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/docker_config.dart';
import '../../domain/usecases/get_docker_config.dart' as config_usecases;

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final config_usecases.GetDockerConfig getDockerConfig;
  final config_usecases.SaveDockerConfig saveDockerConfig;
  final config_usecases.CheckDockerAvailability checkDockerAvailability;

  SettingsBloc({
    required this.getDockerConfig,
    required this.saveDockerConfig,
    required this.checkDockerAvailability,
  }) : super(SettingsInitial()) {
    on<LoadDockerConfig>(_onLoadDockerConfig);
    on<SaveDockerConfig>(_onSaveDockerConfig);
    on<TestDockerConnection>(_onTestDockerConnection);
  }

  Future<void> _onLoadDockerConfig(
    LoadDockerConfig event,
    Emitter<SettingsState> emit,
  ) async {
    emit(DockerConfigLoading());
    try {
      final config = await getDockerConfig();
      emit(DockerConfigLoaded(config));
    } catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }

  Future<void> _onSaveDockerConfig(
    SaveDockerConfig event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsLoading());
    try {
      await saveDockerConfig(event.config);
      emit(SettingsSaved());
    } catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }

  Future<void> _onTestDockerConnection(
    TestDockerConnection event,
    Emitter<SettingsState> emit,
  ) async {
    emit(ConnectionTestLoading());
    try {
      final isAvailable = await checkDockerAvailability(event.config);
      if (isAvailable) {
        emit(ConnectionTestSuccess());
      } else {
        emit(ConnectionTestFailed());
      }
    } catch (e) {
      emit(ConnectionTestFailed());
    }
  }
}