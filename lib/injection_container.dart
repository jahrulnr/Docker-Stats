import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'data/datasources/docker_remote_data_source.dart';
import 'data/repositories/config_repository_impl.dart';
import 'data/repositories/docker_repository_impl.dart';
import 'domain/entities/docker_config.dart';
import 'domain/repositories/config_repository.dart';
import 'domain/repositories/docker_repository.dart';
import 'domain/usecases/get_containers.dart';
import 'domain/usecases/get_container_stats.dart';
import 'domain/usecases/get_docker_config.dart' as config_usecases;
import 'presentation/blocs/docker_stats_bloc.dart';
import 'presentation/blocs/settings_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External
  sl.registerLazySingleton(() => Dio());

  // Data sources
  sl.registerLazySingleton<DockerRemoteDataSource>(
    () => DockerRemoteDataSourceImpl(dio: sl()),
  );

  // Repository
  sl.registerLazySingleton<ConfigRepository>(
    () => ConfigRepositoryImpl(dio: sl()),
  );

  sl.registerLazySingleton<DockerRepository>(
    () => DockerRepositoryImpl(
      remoteDataSource: sl(),
      configRepository: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetContainers(sl()));
  sl.registerLazySingleton(() => GetContainerStats(sl()));
  sl.registerLazySingleton(() => config_usecases.GetDockerConfig(sl()));
  sl.registerLazySingleton(() => config_usecases.SaveDockerConfig(sl()));
  sl.registerLazySingleton(() => config_usecases.CheckDockerAvailability(sl()));

  // BLoC
  sl.registerFactory(() => DockerStatsBloc(
        getContainers: sl(),
        getContainerStats: sl(),
      ));

  sl.registerFactory(() => SettingsBloc(
        getDockerConfig: sl(),
        saveDockerConfig: sl(),
        checkDockerAvailability: sl(),
      ));

  // Domain entities - register default instances if needed
  sl.registerFactory(() => DockerConfig());
}