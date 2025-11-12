class DockerConfig {
  final String dockerHost;
  final bool useUnixSocket;
  final String unixSocketPath;
  final String tcpHost;
  final int tcpPort;

  DockerConfig({
    this.dockerHost = 'http://localhost:2375',
    this.useUnixSocket = true,
    this.unixSocketPath = '/var/run/docker.sock',
    this.tcpHost = 'localhost',
    this.tcpPort = 2375,
  });

  DockerConfig copyWith({
    String? dockerHost,
    bool? useUnixSocket,
    String? unixSocketPath,
    String? tcpHost,
    int? tcpPort,
  }) {
    return DockerConfig(
      dockerHost: dockerHost ?? this.dockerHost,
      useUnixSocket: useUnixSocket ?? this.useUnixSocket,
      unixSocketPath: unixSocketPath ?? this.unixSocketPath,
      tcpHost: tcpHost ?? this.tcpHost,
      tcpPort: tcpPort ?? this.tcpPort,
    );
  }

  String get effectiveDockerHost {
    if (useUnixSocket) {
      return 'http://localhost:2375'; // Always use TCP for HTTP client
    } else {
      return 'http://$tcpHost:$tcpPort';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'dockerHost': dockerHost,
      'useUnixSocket': useUnixSocket,
      'unixSocketPath': unixSocketPath,
      'tcpHost': tcpHost,
      'tcpPort': tcpPort,
    };
  }

  factory DockerConfig.fromJson(Map<String, dynamic> json) {
    return DockerConfig(
      dockerHost: json['dockerHost'] ?? 'http://localhost:2375',
      useUnixSocket: json['useUnixSocket'] ?? true,
      unixSocketPath: json['unixSocketPath'] ?? '/var/run/docker.sock',
      tcpHost: json['tcpHost'] ?? 'localhost',
      tcpPort: json['tcpPort'] ?? 2375,
    );
  }
}