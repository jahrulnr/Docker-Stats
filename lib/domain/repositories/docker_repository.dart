import '../entities/docker_container.dart';

abstract class DockerRepository {
  Future<List<DockerContainer>> getContainers();
  Future<Map<String, dynamic>> getContainerStats(String containerId);
}