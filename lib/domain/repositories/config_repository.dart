import '../entities/docker_config.dart';

abstract class ConfigRepository {
  Future<DockerConfig> loadDockerConfig();
  Future<void> saveDockerConfig(DockerConfig config);
  Future<bool> checkDockerAvailability([DockerConfig? config]);
}