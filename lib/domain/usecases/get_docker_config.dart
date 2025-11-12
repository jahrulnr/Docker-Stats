import '../entities/docker_config.dart';
import '../repositories/config_repository.dart';

class GetDockerConfig {
  final ConfigRepository repository;

  GetDockerConfig(this.repository);

  Future<DockerConfig> call() async {
    return await repository.loadDockerConfig();
  }
}

class SaveDockerConfig {
  final ConfigRepository repository;

  SaveDockerConfig(this.repository);

  Future<void> call(DockerConfig config) async {
    return await repository.saveDockerConfig(config);
  }
}

class CheckDockerAvailability {
  final ConfigRepository repository;

  CheckDockerAvailability(this.repository);

  Future<bool> call([DockerConfig? config]) async {
    return await repository.checkDockerAvailability(config);
  }
}