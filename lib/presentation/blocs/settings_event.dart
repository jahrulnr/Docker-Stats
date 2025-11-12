part of 'settings_bloc.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object> get props => [];
}

class LoadDockerConfig extends SettingsEvent {}

class SaveDockerConfig extends SettingsEvent {
  final DockerConfig config;

  const SaveDockerConfig(this.config);

  @override
  List<Object> get props => [config];
}

class TestDockerConnection extends SettingsEvent {
  final DockerConfig config;

  const TestDockerConnection(this.config);

  @override
  List<Object> get props => [config];
}