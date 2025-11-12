import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../../domain/entities/docker_config.dart';
import '../../domain/repositories/config_repository.dart';

class ConfigRepositoryImpl implements ConfigRepository {
  final Dio dio;
  static const String _configFileName = 'docker_config.json';

  ConfigRepositoryImpl({required this.dio});

  @override
  Future<DockerConfig> loadDockerConfig() async {
    try {
      final configFile = await _getConfigFile();
      if (await configFile.exists()) {
        final contents = await configFile.readAsString();
        final json = jsonDecode(contents);
        return DockerConfig.fromJson(json);
      }
    } catch (e) {
      // Return default config if loading fails
    }
    return DockerConfig();
  }

  @override
  Future<void> saveDockerConfig(DockerConfig config) async {
    final configFile = await _getConfigFile();
    final json = config.toJson();
    await configFile.writeAsString(jsonEncode(json));
  }

  @override
  Future<bool> checkDockerAvailability([DockerConfig? config]) async {
    try {
      final testConfig = config ?? await loadDockerConfig();
      final response = await dio.get(
        '${testConfig.effectiveDockerHost}/_ping',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<File> _getConfigFile() async {
    final appDir = await _getAppConfigDirectory();
    return File('${appDir.path}/$_configFileName');
  }

  Future<Directory> _getAppConfigDirectory() async {
    try {
      // Try to get user config directory first
      final userConfigDir = Directory('${Platform.environment['HOME']}/.config/docker-stats');
      if (!await userConfigDir.exists()) {
        await userConfigDir.create(recursive: true);
      }
      return userConfigDir;
    } catch (e) {
      // Fallback to app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final configDir = Directory('${appDir.path}/config');
      if (!await configDir.exists()) {
        await configDir.create(recursive: true);
      }
      return configDir;
    }
  }
}