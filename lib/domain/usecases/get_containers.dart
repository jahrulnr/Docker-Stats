import '../entities/docker_container.dart';
import '../repositories/docker_repository.dart';

class GetContainers {
  final DockerRepository repository;

  GetContainers(this.repository);

  Future<List<DockerContainer>> call() async {
    return await repository.getContainers();
  }
}