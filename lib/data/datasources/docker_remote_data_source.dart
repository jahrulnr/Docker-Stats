import 'package:dio/dio.dart';
import '../../domain/entities/docker_config.dart';
import '../models/docker_container_model.dart';

abstract class DockerRemoteDataSource {
  Future<List<DockerContainerModel>> getContainers(DockerConfig config);
  Future<Map<String, dynamic>> getContainerStats(String containerId, DockerConfig config);
}

class DockerRemoteDataSourceImpl implements DockerRemoteDataSource {
  final Dio dio;

  DockerRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<DockerContainerModel>> getContainers(DockerConfig config) async {
    try {
      final response = await dio.get('${config.effectiveDockerHost}/containers/json');
      return (response.data as List)
          .map((json) => DockerContainerModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getContainerStats(String containerId, DockerConfig config) async {
    try {
      final response = await dio.get('${config.effectiveDockerHost}/containers/$containerId/stats?stream=false');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}