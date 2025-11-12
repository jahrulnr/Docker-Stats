import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/docker_config.dart';
import '../blocs/settings_bloc.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _unixSocketController;
  late TextEditingController _tcpHostController;
  late TextEditingController _tcpPortController;
  bool _useUnixSocket = true;

  @override
  void initState() {
    super.initState();
    _unixSocketController = TextEditingController(text: '/var/run/docker.sock');
    _tcpHostController = TextEditingController(text: 'localhost');
    _tcpPortController = TextEditingController(text: '2375');

    // Load current config
    context.read<SettingsBloc>().add(LoadDockerConfig());
  }

  @override
  void dispose() {
    _unixSocketController.dispose();
    _tcpHostController.dispose();
    _tcpPortController.dispose();
    super.dispose();
  }

  // Helper method to show in-app popup notifications
  void _showPopupNotification(String message, {bool isError = false}) {
    final overlay = Overlay.of(context);
    late final OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 20,
        right: 20,
        width: 350, // Fixed width for consistency
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isError ? Colors.red.shade600 : Colors.green.shade600,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
                  onPressed: () {
                    overlayEntry.remove();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto remove after 3 seconds (shorter duration)
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettingsBloc, SettingsState>(
      listener: (context, state) {
        if (state is SettingsSaved) {
          _showPopupNotification('Docker settings have been saved successfully.');
        } else if (state is SettingsError) {
          _showPopupNotification(state.message, isError: true);
        } else if (state is DockerConfigLoaded) {
          _updateFormFields(state.config);
        } else if (state is ConnectionTestSuccess) {
          _showPopupNotification('Connection successful! Docker daemon is accessible.');
        } else if (state is ConnectionTestFailed) {
          _showPopupNotification('Connection failed. Please check your Docker configuration.', isError: true);
        }
      },
      builder: (context, state) {
        if (state is SettingsLoading || state is DockerConfigLoading || state is ConnectionTestLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title and close button
                Row(
                  children: [
                    const Text(
                      'Docker Settings',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Docker Connection Settings',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Configure how the app connects to Docker daemon. You can use either Unix socket (local) or TCP connection (remote).',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // Connection Type
                const Text('Connection Type', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('Unix Socket (Local)'),
                        subtitle: const Text('Connect via local socket file'),
                        value: true,
                        groupValue: _useUnixSocket,
                        onChanged: (value) => setState(() => _useUnixSocket = value!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('TCP Connection'),
                        subtitle: const Text('Connect via network'),
                        value: false,
                        groupValue: _useUnixSocket,
                        onChanged: (value) => setState(() => _useUnixSocket = value!),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Unix Socket Settings
                if (_useUnixSocket) ...[
                  const Text('Unix Socket Path', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _unixSocketController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '/var/run/docker.sock',
                      helperText: 'Path to Docker daemon socket file',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter socket path';
                      }
                      return null;
                    },
                  ),
                ],

                // TCP Settings
                if (!_useUnixSocket) ...[
                  const Text('TCP Connection', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _tcpHostController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Host',
                            hintText: 'localhost',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter host';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _tcpPortController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Port',
                            hintText: '2375',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter port';
                            }
                            final port = int.tryParse(value);
                            if (port == null || port < 1 || port > 65535) {
                              return 'Invalid port number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 32),

                // Test Connection Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: state is ConnectionTestLoading ? null : _testConnection,
                    icon: state is ConnectionTestLoading 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.network_check),
                    label: Text(state is ConnectionTestLoading ? 'Testing Connection...' : 'Test Connection'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                    child: const Text('Save Settings'),
                  ),
                ),

                const SizedBox(height: 24),

                // Docker Setup Instructions
                const Text('Docker Setup Instructions', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'To enable Docker API access, configure your Docker daemon:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 12),
                        const Text('1. Edit Docker daemon configuration:'),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'sudo nano /etc/docker/daemon.json',
                            style: TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('2. Add the following configuration:'),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '{\n  "hosts": ["unix:///var/run/docker.sock", "tcp://0.0.0.0:2375"]\n}',
                            style: TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('3. Restart Docker:'),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'sudo systemctl restart docker',
                            style: TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Text(
                            '⚠️ Security Note: This exposes Docker API without authentication. Only use in development/trusted environments.',
                            style: TextStyle(color: Colors.orange[800]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _updateFormFields(DockerConfig config) {
    setState(() {
      _useUnixSocket = config.useUnixSocket;
      _unixSocketController.text = config.unixSocketPath;
      _tcpHostController.text = config.tcpHost;
      _tcpPortController.text = config.tcpPort.toString();
    });
  }

  void _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    final config = _createConfigFromForm();
    context.read<SettingsBloc>().add(TestDockerConnection(config));
  }

  void _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final config = _createConfigFromForm();
    context.read<SettingsBloc>().add(SaveDockerConfig(config));
  }

  DockerConfig _createConfigFromForm() {
    return DockerConfig(
      useUnixSocket: _useUnixSocket,
      unixSocketPath: _unixSocketController.text,
      tcpHost: _tcpHostController.text,
      tcpPort: int.tryParse(_tcpPortController.text) ?? 2375,
    );
  }
}