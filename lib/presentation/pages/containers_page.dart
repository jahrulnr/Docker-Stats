import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/docker_container.dart';
import '../blocs/docker_stats_bloc.dart';
import '../widgets/container_card.dart';

class ContainersPage extends StatefulWidget {
  const ContainersPage({super.key});

  @override
  State<ContainersPage> createState() => _ContainersPageState();
}

class _ContainersPageState extends State<ContainersPage> {
  List<DockerContainer>? _lastContainers;

  @override
  void initState() {
    super.initState();
    _loadContainers();
  }

  void _loadContainers() {
    context.read<DockerStatsBloc>().add(LoadContainers());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Docker Containers'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: BlocBuilder<DockerStatsBloc, DockerStatsState>(
        builder: (context, state) {
          // Only reload containers if we're in an initial state or error state,
          // but not when we're loading stats (ContainerStatsLoading) or have loaded stats (ContainerStatsLoaded)
          if (state is DockerStatsInitial || (state is DockerStatsError && state.message.contains('No containers'))) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadContainers();
            });
          }

          // Store the last known containers when we have them
          if (state is DockerStatsLoaded) {
            _lastContainers = state.containers;
          }

          if (state is DockerStatsLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is DockerStatsLoaded) {
            return ListView.builder(
              itemCount: state.containers.length,
              itemBuilder: (context, index) {
                final container = state.containers[index];
                return ContainerCard(
                  container: container,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/stats',
                      arguments: container.id,
                    );
                  },
                );
              },
            );
          } else if (state is DockerStatsError) {
            return Center(
              child: Text(
                'Error: ${state.message}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            );
          } else if ((state is ContainerStatsLoading || state is ContainerStatsLoaded) && _lastContainers != null) {
            // When we're on the stats page, show the last known containers
            return ListView.builder(
              itemCount: _lastContainers!.length,
              itemBuilder: (context, index) {
                final container = _lastContainers![index];
                return ContainerCard(
                  container: container,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/stats',
                      arguments: container.id,
                    );
                  },
                );
              },
            );
          }
          return const Center(
            child: Text('No containers found'),
          );
        },
      ),
    );
  }
}