import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import 'dart:async';
import '../../domain/entities/docker_container.dart';
import '../../injection_container.dart' as di;
import '../blocs/docker_stats_bloc.dart';
import '../blocs/settings_bloc.dart';
import '../widgets/container_sidebar_item.dart';
import '../../core/utils/logger.dart';
import 'stats_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<DockerContainer> _containers = [];
  String? _selectedContainerId;
  bool _preventSleep = false;
  bool _autoStartEnabled = false;
  Timer? _wakeTimer;

  @override
  void initState() {
    super.initState();
    context.read<DockerStatsBloc>().add(LoadContainers());
    _checkAutoStartStatus();
    _preventScreenSleep(); // Enable sleep prevention by default
  }

  @override
  void dispose() {
    _restoreScreenSettings();
    _wakeTimer?.cancel();
    super.dispose();
  }

  void _onContainerSelected(String containerId) {
    setState(() {
      _selectedContainerId = containerId;
    });
  }

  // Example method to run Docker commands
  Future<void> _runDockerCommand(String command) async {
    try {
      final result = await Process.run('docker', command.split(' '));
      AppLogger.info('Docker command output: ${result.stdout}');
      if (result.stderr.isNotEmpty) {
        AppLogger.warning('Docker command error: ${result.stderr}');
      }
    } catch (e) {
      AppLogger.error('Failed to run Docker command: $e');
    }
  }

  // Example: Get Docker version
  Future<String> _getDockerVersion() async {
    try {
      final result = await Process.run('docker', ['--version']);
      return result.stdout.toString().trim();
    } catch (e) {
      return 'Error: $e';
    }
  }

  // Example method to demonstrate Docker command execution
  void _runDockerCommandExample(BuildContext context) async {
    // Example: Run docker ps command
    await _runDockerCommand('ps --format "table {{.Names}}\\t{{.Status}}\\t{{.Ports}}"');
    
    // Show result in a snackbar
    final version = await _getDockerVersion();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Docker Version: $version')),
      );
    }
  }

  // Prevent screen sleep/lock
  Future<void> _preventScreenSleep() async {
    try {
      // For GNOME desktop environment
      await Process.run('gsettings', ['set', 'org.gnome.desktop.session', 'idle-delay', '0']);
      await Process.run('gsettings', ['set', 'org.gnome.desktop.lockdown', 'disable-lock-screen', 'true']);
      
      // For X11 systems (fallback)
      await Process.run('xset', ['s', 'off']);
      await Process.run('xset', ['-dpms']);
      
      // Start periodic wake signal (every 30 seconds)
      _startWakeTimer();
      
      setState(() {
        _preventSleep = true;
      });
      
      AppLogger.info('Screen sleep prevention enabled');
    } catch (e) {
      AppLogger.error('Failed to prevent screen sleep: $e');
      // Try alternative methods
      _tryAlternativeWakeMethods();
    }
  }

  // Restore normal screen settings
  Future<void> _restoreScreenSettings() async {
    try {
      // Stop wake timer
      _wakeTimer?.cancel();
      
      // Restore GNOME settings
      await Process.run('gsettings', ['set', 'org.gnome.desktop.session', 'idle-delay', '300']); // 5 minutes
      await Process.run('gsettings', ['set', 'org.gnome.desktop.lockdown', 'disable-lock-screen', 'false']);
      
      // Restore X11 settings
      await Process.run('xset', ['s', 'on']);
      await Process.run('xset', ['+dpms']);
      
      setState(() {
        _preventSleep = false;
      });
      
      AppLogger.info('Screen settings restored');
    } catch (e) {
      AppLogger.error('Failed to restore screen settings: $e');
    }
  }

  // Start periodic wake signal
  void _startWakeTimer() {
    _wakeTimer?.cancel();
    _wakeTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      // Send a small activity signal to keep screen awake
      // This is a fallback in case the system settings don't work
      _sendWakeSignal();
    });
  }

  // Send wake signal (fallback method)
  Future<void> _sendWakeSignal() async {
    try {
      // Try to simulate activity (this may not work on all systems)
      await Process.run('xdotool', ['mousemove_relative', '1', '1']);
      await Process.run('xdotool', ['mousemove_relative', '--', '1', '--1']);
    } catch (e) {
      // xdotool may not be available, that's ok
    }
  }

  // Try alternative wake methods if primary ones fail
  Future<void> _tryAlternativeWakeMethods() async {
    try {
      // Try caffeine (if installed)
      await Process.run('caffeine', []);
    } catch (e) {
      try {
        // Try gnome-screensaver-command
        await Process.run('gnome-screensaver-command', ['--inhibit']);
      } catch (e2) {
        AppLogger.warning('No alternative wake methods available');
      }
    }
  }

  // Toggle sleep prevention
  void _toggleSleepPrevention() {
    if (_preventSleep) {
      _restoreScreenSettings();
    } else {
      _preventScreenSleep();
    }
  }

  // Check if auto-start is enabled
  Future<void> _checkAutoStartStatus() async {
    try {
      final homeDir = Platform.environment['HOME'];
      if (homeDir != null) {
        final autostartDir = Directory('$homeDir/.config/autostart');
        final desktopFile = File('${autostartDir.path}/docker-status.desktop');

        final enabled = await desktopFile.exists();
        setState(() {
          _autoStartEnabled = enabled;
        });
      }
    } catch (e) {
      AppLogger.error('Failed to check auto-start status: $e');
    }
  }

  // Toggle auto-start
  Future<void> _toggleAutoStart() async {
    try {
      final homeDir = Platform.environment['HOME'];
      if (homeDir == null) return;

      final autostartDir = Directory('$homeDir/.config/autostart');
      await autostartDir.create(recursive: true);

      final desktopFile = File('${autostartDir.path}/docker-status.desktop');

      if (_autoStartEnabled) {
        // Disable auto-start
        if (await desktopFile.exists()) {
          await desktopFile.delete();
        }
        setState(() {
          _autoStartEnabled = false;
        });
        AppLogger.info('Auto-start disabled');
      } else {
        // Enable auto-start
        final executablePath = Platform.resolvedExecutable;
        final desktopContent = '''[Desktop Entry]
Type=Application
Name=Docker Status
Comment=Docker container monitoring application
Exec=$executablePath
Terminal=false
Categories=Utility;System;
StartupNotify=true
''';

        await desktopFile.writeAsString(desktopContent);
        setState(() {
          _autoStartEnabled = true;
        });
        AppLogger.info('Auto-start enabled');
      }
    } catch (e) {
      AppLogger.error('Failed to toggle auto-start: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to toggle auto-start: $e')),
        );
      }
    }
  }

  void _openSettings() {
    showDialog(
      context: context,
      builder: (context) => BlocProvider(
        create: (_) => di.sl<SettingsBloc>(),
        child: Dialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
            child: const SettingsPage(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<DockerStatsBloc, DockerStatsState>(
        builder: (context, state) {
                // Update containers list when loaded
                if (state is DockerStatsLoaded) {
                  _containers = List.from(state.containers)
                    ..sort((a, b) => a.name.compareTo(b.name));

                  // Set default selection to first container if not already set
                  if (_selectedContainerId == null && _containers.isNotEmpty) {
                    _selectedContainerId = _containers.first.id;
                  }
                }

                return Row(
                  children: [
                    // Sidebar with containers
                    Container(
                      width: 320,
                      color: Theme.of(context).cardColor,
                      child: Column(
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Theme.of(context).dividerColor,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.dock,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Containers',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: Icon(_autoStartEnabled ? Icons.launch : Icons.launch_outlined),
                                  onPressed: _toggleAutoStart,
                                  tooltip: _autoStartEnabled ? 'Disable auto-start' : 'Enable auto-start',
                                  iconSize: 16,
                                ),
                                IconButton(
                                  icon: Icon(_preventSleep ? Icons.visibility : Icons.visibility_off),
                                  onPressed: _toggleSleepPrevention,
                                  tooltip: _preventSleep ? 'Allow screen sleep' : 'Prevent screen sleep',
                                  iconSize: 16,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.terminal),
                                  onPressed: () => _runDockerCommandExample(context),
                                  tooltip: 'Run Docker Command',
                                  iconSize: 16,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.settings),
                                  onPressed: _openSettings,
                                  tooltip: 'Docker Settings',
                                  iconSize: 16,
                                ),
                              ],
                            ),
                          ),
                          // Container list
                          Expanded(
                            child: _buildContainerList(),
                          ),
                        ],
                      ),
                    ),
                    // Vertical divider
                    Container(
                      width: 1,
                      color: Theme.of(context).dividerColor,
                    ),
                    // Main content area
                    Expanded(
                      child: _selectedContainerId != null
                          ? Column(
                              children: [
                                // Status bars
                                if (_autoStartEnabled)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.launch,
                                          color: Theme.of(context).colorScheme.secondary,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Auto-start enabled',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).colorScheme.secondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (_preventSleep)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.visibility,
                                          color: Theme.of(context).colorScheme.primary,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Screen sleep prevention active',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                // Stats page
                                Expanded(
                                  child: StatsPage(
                                    key: ValueKey('stats_$_selectedContainerId'),
                                    containerId: _selectedContainerId!,
                                  ),
                                ),
                              ],
                            )
                          : const Center(
                              child: Text('Select a container to view stats'),
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildContainerList() {
    if (_containers.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return ListView.builder(
      itemCount: _containers.length,
      itemBuilder: (context, index) {
        final container = _containers[index];
        final isSelected = container.id == _selectedContainerId;

        return ContainerSidebarItem(
          container: container,
          isSelected: isSelected,
          onTap: () => _onContainerSelected(container.id),
        );
      },
    );
  }
}