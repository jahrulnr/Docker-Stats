import '../repositories/docker_repository.dart';

class GetContainerStats {
  final DockerRepository repository;

  GetContainerStats(this.repository);

  Future<Map<String, dynamic>> call(String containerId) async {
    return await repository.getContainerStats(containerId);
  }
}