import '../../domain/entities/docker_container.dart';
import '../../domain/repositories/docker_repository.dart';
import '../../domain/repositories/config_repository.dart';
import '../datasources/docker_remote_data_source.dart';

class DockerRepositoryImpl implements DockerRepository {
  final DockerRemoteDataSource remoteDataSource;
  final ConfigRepository configRepository;

  DockerRepositoryImpl({
    required this.remoteDataSource,
    required this.configRepository,
  });

  @override
  Future<List<DockerContainer>> getContainers() async {
    final config = await configRepository.loadDockerConfig();
    final models = await remoteDataSource.getContainers(config);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<Map<String, dynamic>> getContainerStats(String containerId) async {
    final config = await configRepository.loadDockerConfig();
    return await remoteDataSource.getContainerStats(containerId, config);
  }
}