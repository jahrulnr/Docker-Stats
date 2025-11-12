class DockerContainer {
  final String id;
  final String name;
  final String image;
  final String status;
  final Map<String, dynamic> stats;

  DockerContainer({
    required this.id,
    required this.name,
    required this.image,
    required this.status,
    required this.stats,
  });
}