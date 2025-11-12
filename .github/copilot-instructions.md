# Flutter Docker Stats App - AI Agent Guidelines

## Architecture Overview
This Flutter app follows **Clean Architecture** with strict layer separation:
- `presentation/` - UI components, BLoC, pages, widgets, themes
- `domain/` - Business logic, entities, repositories (interfaces), use cases
- `data/` - External data sources, models, repositories (implementations)

**Never** allow domain layer to depend on presentation or data layers. Data layer implementations should depend only on domain interfaces.

## State Management - BLoC Pattern
Use flutter_bloc with this exact structure:
```dart
class FeatureBloc extends Bloc<FeatureEvent, FeatureState> {
  final UseCase usecase;

  FeatureBloc({required this.usecase}) : super(FeatureInitial()) {
    on<FeatureEvent>(_onEvent);
  }

  Future<void> _onEvent(FeatureEvent event, Emitter<FeatureState> emit) async {
    emit(FeatureLoading());
    try {
      final result = await usecase();
      emit(FeatureLoaded(data: result));
    } catch (e) {
      emit(FeatureError(message: e.toString()));
    }
  }
}
```

**Always** create separate `event.dart` and `state.dart` files as `part of 'bloc.dart'`.

## Dependency Injection - GetIt Pattern
Register dependencies in `injection_container.dart` with this hierarchy:
```dart
// BLoC (factory - new instance each time)
sl.registerFactory(() => FeatureBloc(usecase: sl()));

// Use cases (lazy singleton - created once when first accessed)
sl.registerLazySingleton(() => GetFeature(sl()));

// Repositories (lazy singleton)
sl.registerLazySingleton<FeatureRepository>(
  () => FeatureRepositoryImpl(remoteDataSource: sl()),
);

// Data sources (lazy singleton)
sl.registerLazySingleton<FeatureRemoteDataSource>(
  () => FeatureRemoteDataSourceImpl(dio: sl()),
);

// External dependencies (lazy singleton)
sl.registerLazySingleton(() => Dio());
```

## Theme - Dracula Color Palette
Use predefined colors from `AppTheme` class:
- `AppTheme.background` (0xFF282A36) - Main background
- `AppTheme.currentLine` (0xFF44475A) - Cards and surfaces
- `AppTheme.foreground` (0xFFF8F8F2) - Primary text
- `AppTheme.cyan` (0xFF8BE9FD) - Headings and accents
- `AppTheme.green` (0xFF50FA7B) - Success states
- `AppTheme.purple` (0xFFBD93F9) - Primary actions
- `AppTheme.red` (0xFFFF5555) - Errors
- `AppTheme.orange` (0xFFFFB86C) - Warnings

Apply theme colors consistently across all UI components.

## Docker API Integration
Connect to Docker daemon via HTTP API at `http://localhost:2375`:
```dart
// Get containers
final response = await dio.get('http://localhost:2375/containers/json');

// Get container stats (non-streaming)
final response = await dio.get('http://localhost:2375/containers/$containerId/stats?stream=false');
```

**Security Note**: This exposes Docker API without authentication. Only use in development/trusted environments.

## Desktop System Integration
Use `Process.run()` for system commands with proper error handling:
```dart
// GNOME settings for sleep prevention
await Process.run('gsettings', ['set', 'org.gnome.desktop.session', 'idle-delay', '0']);

// X11 settings as fallback
await Process.run('xset', ['s', 'off']);
await Process.run('xset', ['-dpms']);

// Auto-start desktop file creation
final desktopContent = '''[Desktop Entry]
Type=Application
Name=Docker Status
Exec=${Platform.resolvedExecutable}
Terminal=false
Categories=Utility;System;
''';
await File('${Platform.environment['HOME']}/.config/autostart/app.desktop')
    .writeAsString(desktopContent);
```

## UI Patterns
### Cards
Use consistent card styling with Dracula theme:
```dart
Card(
  color: Theme.of(context).cardColor, // AppTheme.currentLine
  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  child: // content
)
```

### Charts
Use fl_chart for data visualization with Dracula colors:
```dart
LineChart(
  LineChartData(
    gridData: FlGridData(show: false),
    titlesData: FlTitlesData(show: false),
    borderData: FlBorderData(show: false),
    lineBarsData: [
      LineChartBarData(
        spots: dataPoints,
        isCurved: true,
        color: AppTheme.cyan, // Use theme colors
        barWidth: 3,
        belowBarData: BarAreaData(
          show: true,
          color: AppTheme.cyan.withOpacity(0.1),
        ),
        dotData: FlDotData(show: false),
      ),
    ],
  ),
)
```

### In-App Notifications
Use custom overlay notifications instead of system notifications:
```dart
void _showPopupNotification(String message, {bool isError = false}) {
  final overlay = Overlay.of(context);
  late final OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: 20,
      right: 20,
      width: 350,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isError ? Colors.red.shade600 : Colors.green.shade600,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Row(children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis)),
            IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 18), onPressed: () => overlayEntry.remove(), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          ]),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);
  Future.delayed(const Duration(seconds: 3), () => overlayEntry.mounted ? overlayEntry.remove() : null);
}
```

## Error Handling
Follow consistent error handling in BLoC:
```dart
try {
  final result = await usecase();
  emit(SuccessState(data: result));
} catch (e) {
  emit(ErrorState(message: e.toString()));
}
```

Display errors in UI with theme colors:
```dart
Text(
  'Error: ${state.message}',
  style: TextStyle(color: Theme.of(context).colorScheme.error),
)
```

## File Organization
- Keep BLoC files together: `bloc.dart`, `event.dart`, `state.dart`
- Group related widgets in `widgets/` directory
- Use clear naming: `container_card.dart`, `stats_chart.dart`
- Separate theme configuration in `theme/app_theme.dart`

## Build System - Docker + Makefile
Use the Makefile for all builds - no shell scripts:
```bash
# Build both architectures
make build-all

# Build specific architecture
make build-amd64
make build-arm64

# Clean and test
make clean && make test

# Install locally
sudo make install
```

**Docker Configuration** (required for development):
```json
// /etc/docker/daemon.json
{
  "hosts": ["unix:///var/run/docker.sock", "tcp://0.0.0.0:2375"]
}
```
Then `sudo systemctl restart docker`

## .deb Package Structure
Packages install to `/opt/docker-stats/` with desktop integration:
- **Binary**: `/opt/docker-stats/docker_stats_app`
- **Desktop file**: `/usr/share/applications/docker-stats.desktop`
- **Icon**: `/usr/share/icons/hicolor/512x512/apps/docker-stats.png`
- **Post-install**: Updates desktop database and icon cache

## Development Workflow
1. **Build**: `flutter pub get` then `flutter run`
2. **Test**: `flutter test` (when tests are added)
3. **Lint**: `flutter analyze`
4. **Format**: `flutter format .`
5. **Docker Setup**: Configure daemon.json for TCP access on port 2375

## Key Dependencies
- `flutter_bloc`: State management
- `dio`: HTTP client for Docker API
- `get_it`: Dependency injection
- `equatable`: State comparison
- `fl_chart`: Data visualization
- `bitsdojo_window`: Desktop window management
- `path_provider`: Config file storage
- `logging`: Framework logging

## Common Patterns
- **Models**: Extend domain entities with `fromJson()` factory methods
- **Status Colors**: Green for running, red for exited, yellow for other states
- **Chart Data**: Convert Docker stats to `FlSpot` objects for visualization
- **Error States**: Always include error handling in BLoC with user-friendly messages
- **System Integration**: Use `Process.run()` with fallbacks for desktop features
- **Startup Flow**: Docker availability check on app launch with fallback screens
- **Config Storage**: JSON-based config in `~/.config/docker-stats/docker_config.json`

## Critical Integration Points
- **bitsdojo_window**: Required for desktop window management - configure in `main.dart`
- **Docker daemon config**: Must enable TCP access on port 2375 for development
- **System permissions**: App needs access to Docker socket and system commands
- **Desktop integration**: Auto-start and desktop file creation for system integration

## Dependency Injection - GetIt Pattern
Register dependencies in `injection_container.dart` with this hierarchy:
```dart
// BLoC (factory - new instance each time)
sl.registerFactory(() => FeatureBloc(usecase: sl()));

// Use cases (lazy singleton - created once when first accessed)
sl.registerLazySingleton(() => GetFeature(sl()));

// Repositories (lazy singleton)
sl.registerLazySingleton<FeatureRepository>(
  () => FeatureRepositoryImpl(remoteDataSource: sl()),
);

// Data sources (lazy singleton)
sl.registerLazySingleton<FeatureRemoteDataSource>(
  () => FeatureRemoteDataSourceImpl(dio: sl()),
);

// External dependencies (lazy singleton)
sl.registerLazySingleton(() => Dio());
```

## Theme - Dracula Color Palette
Use predefined colors from `AppTheme` class:
- `AppTheme.background` (0xFF282A36) - Main background
- `AppTheme.currentLine` (0xFF44475A) - Cards and surfaces
- `AppTheme.foreground` (0xFFF8F8F2) - Primary text
- `AppTheme.cyan` (0xFF8BE9FD) - Headings and accents
- `AppTheme.green` (0xFF50FA7B) - Success states
- `AppTheme.purple` (0xFFBD93F9) - Primary actions
- `AppTheme.red` (0xFFFF5555) - Errors
- `AppTheme.orange` (0xFFFFB86C) - Warnings

Apply theme colors consistently across all UI components.

## Docker API Integration
Connect to Docker daemon via HTTP API at `http://localhost:2375`:
```dart
// Get containers
final response = await dio.get('http://localhost:2375/containers/json');

// Get container stats (non-streaming)
final response = await dio.get('http://localhost:2375/containers/$containerId/stats?stream=false');
```

**Security Note**: This exposes Docker API without authentication. Only use in development/trusted environments.

## UI Patterns
### Cards
Use consistent card styling with Dracula theme:
```dart
Card(
  color: Theme.of(context).cardColor, // AppTheme.currentLine
  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  child: // content
)
```

### Charts
Use fl_chart for data visualization with Dracula colors:
```dart
LineChart(
  LineChartData(
    gridData: FlGridData(show: false),
    titlesData: FlTitlesData(show: false),
    borderData: FlBorderData(show: false),
    lineBarsData: [
      LineChartBarData(
        spots: dataPoints,
        isCurved: true,
        color: AppTheme.cyan, // Use theme colors
        barWidth: 3,
        belowBarData: BarAreaData(
          show: true,
          color: AppTheme.cyan.withOpacity(0.1),
        ),
        dotData: FlDotData(show: false),
      ),
    ],
  ),
)
```

### Navigation
Use named routes with arguments:
```dart
// Define routes in MaterialApp
routes: {
  '/': (context) => const HomePage(),
  '/detail': (context) => DetailPage(
    id: ModalRoute.of(context)!.settings.arguments as String,
  ),
}

// Navigate
Navigator.pushNamed(context, '/detail', arguments: itemId);
```

## Error Handling
Follow consistent error handling in BLoC:
```dart
try {
  final result = await usecase();
  emit(SuccessState(data: result));
} catch (e) {
  emit(ErrorState(message: e.toString()));
}
```

Display errors in UI with theme colors:
```dart
Text(
  'Error: ${state.message}',
  style: TextStyle(color: Theme.of(context).colorScheme.error),
)
```

## File Organization
- Keep BLoC files together: `bloc.dart`, `event.dart`, `state.dart`
- Group related widgets in `widgets/` directory
- Use clear naming: `container_card.dart`, `stats_chart.dart`
- Separate theme configuration in `theme/app_theme.dart`

## Docker Configuration (Critical for Development)
To enable Docker API access for development:
```json
// /etc/docker/daemon.json
{
  "hosts": ["unix:///var/run/docker.sock", "tcp://0.0.0.0:2375"]
}
```
Then restart Docker: `sudo systemctl restart docker`

**Security**: This exposes Docker API without authentication. Only use in development/trusted environments.

## Development Workflow
1. **Build**: `flutter pub get` then `flutter run`
2. **Test**: `flutter test` (when tests are added)
3. **Lint**: `flutter analyze`
4. **Format**: `flutter format .`
5. **Docker Setup**: Configure daemon.json for TCP access on port 2375

## Key Dependencies
- `flutter_bloc`: State management
- `dio`: HTTP client for Docker API
- `get_it`: Dependency injection
- `equatable`: State comparison
- `fl_chart`: Data visualization
- `lottie`: Animations (future use)

## Common Patterns
- **Models**: Extend domain entities with `fromJson()` factory methods
- **Status Colors**: Green for running, red for exited, yellow for other states
- **Chart Data**: Convert Docker stats to `FlSpot` objects for visualization
- **Error States**: Always include error handling in BLoC with user-friendly messages