part of 'settings_bloc.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class DockerConfigLoading extends SettingsState {}

class DockerConfigLoaded extends SettingsState {
  final DockerConfig config;

  const DockerConfigLoaded(this.config);

  @override
  List<Object> get props => [config];
}

class SettingsSaved extends SettingsState {}

class ConnectionTestLoading extends SettingsState {}

class ConnectionTestSuccess extends SettingsState {}

class ConnectionTestFailed extends SettingsState {}

class SettingsError extends SettingsState {
  final String message;

  const SettingsError({required this.message});

  @override
  List<Object> get props => [message];
}