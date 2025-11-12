# Docker Stats App

<p align="center">
  <img src="icon.jpg" alt="Docker Stats Logo" width="200"/>
</p>

A Flutter desktop application for monitoring Docker containers with real-time statistics, interactive charts, and system integration features.

## Story

This app was born from a simple need: monitoring my Orange Pi's AI workloads running in Docker containers. As someone running a small AI setup on limited hardware, I needed an elegant way to keep track of performance metrics that would actually motivate me to optimize and maintain my system.

Built entirely by an AI agent, this app sometimes surprises with unexpected details and features that make monitoring Docker containers not just functional, but actually enjoyable. The clean, modern interface turns what could be a mundane task into something that sparks curiosity and drives continuous improvement.

Whether you're running AI models, web services, or any containerized workloads on your Orange Pi or other single-board computers, this app provides the beautiful insights you need to stay motivated and informed.

## Features

- 🐳 **Real-time Docker Monitoring**: Monitor container CPU, memory, network, and disk usage
- 📊 **Interactive Charts**: Beautiful charts powered by fl_chart for data visualization
- 🔄 **Container Switching**: Easily switch between different containers
- ⚙️ **Flexible Docker Configuration**: Support for Unix socket and TCP connections to local/remote Docker daemons
- 🖥️ **Connection Health Check**: Automatic Docker availability detection on startup
- 💤 **Screen Sleep Prevention**: Keep your screen awake while monitoring containers
- 🚀 **Auto-start**: Configure the app to start automatically on system boot
- 🖥️ **Desktop Integration**: Native Linux desktop app with proper window management
- 📦 **Cross-Architecture**: Available as .deb packages for both AMD64 and ARM64

## Screenshots

<p align="center">
  <img src="screenshots/dashboard.png" alt="Docker Stats Dashboard"/>
</p>

## Installation

### From .deb Package (Recommended)

Download the latest .deb package from the [Releases](https://github.com/your-org/docker-stats/releases) page.

#### For AMD64 systems:
```bash
sudo dpkg -i docker-stats-app_1.0.0_amd64.deb
sudo apt-get install -f  # Install any missing dependencies
```

#### For ARM64 systems:
```bash
sudo dpkg -i docker-stats-app_1.0.0_arm64.deb
sudo apt-get install -f  # Install any missing dependencies
```

The .deb package includes:
- ✅ **App Icon**: Installed to system icon theme
- ✅ **Desktop Launcher**: Added to application menu
- ✅ **Auto-start Support**: Ready for system integration

### Uninstallation

To uninstall the Docker Stats app:

#### Using apt (Recommended):
```bash
sudo apt remove docker-stats-app
```

#### Using dpkg:
```bash
sudo dpkg -r docker-stats-app
```

#### Complete Removal (including configuration):
```bash
# Remove the package
sudo apt purge docker-stats-app

# Remove user configuration (optional)
rm -rf ~/.config/docker-stats

# Remove system cache (optional)
rm -rf ~/.cache/docker-stats
```

**Note**: The uninstallation will remove:
- The application binary from `/opt/docker-stats/`
- Desktop launcher and icon
- Auto-start configuration (if enabled)

### From Source

1. **Prerequisites**:
   - Flutter SDK (3.19.3 or later)
   - Linux desktop environment
   - Docker daemon running

2. **Clone and build**:
   ```bash
   git clone https://github.com/jahrulnr/Docker-Stats.git
   cd docker-stats
   flutter pub get
   flutter build linux --release
   ```

3. **Run**:
   ```bash
   ./build/linux/x64/release/bundle/docker_stats_app
   ```

### Building .deb Packages

#### Using Makefile (Recommended)

The project includes a Makefile for easy building with Docker:

```bash
# Build for both architectures
make build-all

# Build for specific architecture
make build-amd64
make build-arm64

# Clean build artifacts
make clean

# Start development environment
make dev

# Test built packages
make test

# Install locally (requires sudo)
make install
```

#### Manual Build

Use the provided Makefile:

```bash
# Build for both architectures
make build-all

# Build for specific architecture
make build-amd64
make build-arm64
```

This will generate .deb packages in the `dist/` directory for both architectures using Docker.

### Requirements for Building

- Flutter SDK
- `flutter_distributor` (installed automatically by build script)
- `dpkg-deb` (usually pre-installed on Debian/Ubuntu)
- For ARM64 builds: QEMU user emulation (optional, for cross-compilation)

## Docker Setup

The app supports flexible Docker connection configurations. You can connect to Docker using either Unix socket (local) or TCP connection (remote/external).

### Quick Setup (Default)

For most users, the default configuration should work:

1. **Install Docker** (if not already installed):
   ```bash
   # Ubuntu/Debian
   sudo apt update && sudo apt install docker.io
   
   # Add user to docker group
   sudo usermod -aG docker $USER
   ```

2. **Start Docker service**:
   ```bash
   sudo systemctl start docker
   sudo systemctl enable docker
   ```

3. **Run the app** - it will automatically detect and connect to Docker

### Advanced Configuration

For custom Docker setups (remote Docker hosts, different socket paths, etc.):

1. **Launch the app**
2. **Click the settings icon** (⚙️) in the title bar
3. **Configure your Docker connection**:
   - **Unix Socket**: For local Docker daemon (default: `/var/run/docker.sock`)
   - **TCP Connection**: For remote Docker hosts (specify host and port)

#### For Unix Socket Access:
Ensure the socket file exists and is accessible:
```bash
ls -la /var/run/docker.sock
# Should show: srw-rw---- 1 root docker 0 ...

# Add user to docker group if needed
sudo usermod -aG docker $USER
```

### Configuration Storage

Docker connection settings are saved to:
- **Primary**: `~/.config/docker-stats/docker_config.json`
- **Fallback**: App installation directory

### Troubleshooting

**"Docker Not Available" on startup:**
- Docker daemon is not running
- Docker socket not accessible
- Wrong connection configuration

**Solutions:**
1. Check if Docker is running: `sudo systemctl status docker`
2. Verify socket permissions: `ls -la /var/run/docker.sock`
3. Open app settings to reconfigure connection
4. Restart Docker service if needed

⚠️ **Security Note**: TCP connections expose Docker API without authentication. Only use in trusted environments.

## Development

### Prerequisites

- Flutter SDK >= 3.19.3
- Dart SDK >= 3.3.1
- Linux development environment

### Setup

```bash
flutter pub get
flutter run -d linux
```

### Architecture

This app follows Clean Architecture principles:

- **Presentation Layer**: UI components, BLoC state management
- **Domain Layer**: Business logic, entities, use cases
- **Data Layer**: External data sources, repositories, models

### Key Dependencies

- `flutter_bloc`: State management
- `dio`: HTTP client for Docker API
- `fl_chart`: Data visualization
- `bitsdojo_window`: Desktop window management
- `get_it`: Dependency injection

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

If you encounter any issues or have questions:

1. Check the [Issues](https://github.com/your-org/docker-stats/issues) page
2. Create a new issue with detailed information
3. Include your system information and Flutter version
