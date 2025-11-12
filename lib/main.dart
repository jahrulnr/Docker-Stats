import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'domain/entities/docker_config.dart';
import 'injection_container.dart' as di;
import 'presentation/blocs/docker_stats_bloc.dart';
import 'presentation/blocs/settings_bloc.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/settings_page.dart';
import 'presentation/theme/app_theme.dart';
import 'core/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logger
  AppLogger.init();

  await di.init();

  // Check Docker availability on startup
  final settingsBloc = di.sl<SettingsBloc>();
  settingsBloc.add(TestDockerConnection(DockerConfig())); // Use default config for initial check

  // Configure window for desktop
  doWhenWindowReady(() {
    const initialSize = Size(1200, 800);
    appWindow.minSize = const Size(800, 600);
    appWindow.size = initialSize;
    appWindow.alignment = Alignment.center;
    appWindow.show();
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<DockerStatsBloc>()),
        BlocProvider(create: (_) => di.sl<SettingsBloc>()),
      ],
      child: MaterialApp(
        title: 'Docker Status',
        theme: AppTheme.darkTheme,
        home: const StartupWrapper(),
      ),
    );
  }
}

class StartupWrapper extends StatefulWidget {
  const StartupWrapper({super.key});

  @override
  State<StartupWrapper> createState() => _StartupWrapperState();
}

class _StartupWrapperState extends State<StartupWrapper> {
  bool _dockerChecked = false;
  bool _dockerAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkDockerAvailability();
  }

  Future<void> _checkDockerAvailability() async {
    final settingsBloc = context.read<SettingsBloc>();
    settingsBloc.add(TestDockerConnection(DockerConfig())); // Use default config
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsBloc, SettingsState>(
      listener: (context, state) {
        if (state is ConnectionTestSuccess) {
          setState(() {
            _dockerChecked = true;
            _dockerAvailable = true;
          });
        } else if (state is ConnectionTestFailed) {
          setState(() {
            _dockerChecked = true;
            _dockerAvailable = false;
          });
        }
      },
      child: _dockerChecked
          ? _dockerAvailable
              ? const HomePage()
              : const DockerNotAvailablePage()
          : const SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Checking Docker connection...'),
          ],
        ),
      ),
    );
  }
}

class DockerNotAvailablePage extends StatelessWidget {
  const DockerNotAvailablePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.dock,
                size: 80,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Docker Not Available',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Docker daemon is not running or not accessible. Please ensure Docker is installed and running.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  // Open settings to configure Docker connection
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
                },
                icon: const Icon(Icons.settings),
                label: const Text('Configure Docker Connection'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Retry the check
                  context.read<SettingsBloc>().add(TestDockerConnection(DockerConfig()));
                },
                child: const Text('Retry Connection'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
