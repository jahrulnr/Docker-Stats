import '../../domain/entities/docker_container.dart';

class DockerContainerModel {
  final String id;
  final String name;
  final String image;
  final String status;
  final Map<String, dynamic> stats;

  DockerContainerModel({
    required this.id,
    required this.name,
    required this.image,
    required this.status,
    required this.stats,
  });

  factory DockerContainerModel.fromJson(Map<String, dynamic> json) {
    return DockerContainerModel(
      id: json['Id'] ?? '',
      name: json['Names']?[0] ?? '',
      image: json['Image'] ?? '',
      status: json['Status'] ?? '',
      stats: {},
    );
  }

  DockerContainer toEntity() {
    return DockerContainer(
      id: id,
      name: name,
      image: image,
      status: status,
      stats: stats,
    );
  }
}