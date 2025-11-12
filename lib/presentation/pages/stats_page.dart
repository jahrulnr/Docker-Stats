import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../blocs/docker_stats_bloc.dart';
import '../widgets/stats_chart.dart';

class StatsPage extends StatefulWidget {
  final String containerId;

  const StatsPage({super.key, required this.containerId});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  Timer? _timer;
  Timer? _uiUpdateTimer;
  
  // Store historical data for real-time charts
  final List<double> _cpuHistory = [];
  final List<double> _memoryHistory = [];
  final List<double> _networkRxHistory = [];
  final List<double> _networkTxHistory = [];
  final int _maxDataPoints = 30; // Show last 30 data points (60 seconds at 2-second intervals)

  Map<String, dynamic>? _lastKnownStats;

  @override
  void initState() {
    super.initState();
    context.read<DockerStatsBloc>().add(LoadContainerStats(widget.containerId));
    // Refresh stats every 2 seconds for real-time feel
    _startPeriodicUpdates();
    // Force UI updates every 2 seconds to keep charts animating
    _startUIUpdates();
  }

  @override
  void didUpdateWidget(StatsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If container changed, reset everything
    if (oldWidget.containerId != widget.containerId) {
      _resetState();
      context.read<DockerStatsBloc>().add(LoadContainerStats(widget.containerId));
    }
  }

  void _resetState() {
    // Clear all historical data
    _cpuHistory.clear();
    _memoryHistory.clear();
    _networkRxHistory.clear();
    _networkTxHistory.clear();
    
    // Clear last known stats
    _lastKnownStats = null;
    
    // Stop existing timers
    _stopPeriodicUpdates();
    _stopUIUpdates();
    
    // Restart timers for new container
    _startPeriodicUpdates();
    _startUIUpdates();
  }

  void _startPeriodicUpdates() {
    // Update stats every 2 seconds
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        context.read<DockerStatsBloc>().add(UpdateContainerStats(widget.containerId));
      }
    });
  }

  void _stopPeriodicUpdates() {
    _timer?.cancel();
  }

  void _startUIUpdates() {
    // Force UI updates every 2 seconds to keep charts refreshing
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted && _lastKnownStats != null) {
        setState(() {});
      }
    });
  }

  void _stopUIUpdates() {
    _uiUpdateTimer?.cancel();
  }

  void _updateHistoricalData(Map<String, dynamic> stats) {
    _lastKnownStats = stats;
    
    // Calculate current values
    final cpuUsage = stats['cpu_stats']?['cpu_usage']?['total_usage'] ?? 0;
    final systemCpuUsage = stats['cpu_stats']?['system_cpu_usage'] ?? 1;
    final onlineCpus = stats['cpu_stats']?['online_cpus'] ?? 1;
    final cpuPercent = ((cpuUsage / systemCpuUsage) * onlineCpus * 100).clamp(0.0, 100.0);

    final memoryUsage = stats['memory_stats']?['usage'] ?? 0;
    final memoryLimit = stats['memory_stats']?['limit'] ?? 1;
    final memoryPercent = (memoryUsage / memoryLimit * 100).clamp(0.0, 100.0);

    final networkStats = stats['networks']?['eth0'] ?? {};
    final rxBytes = networkStats['rx_bytes'] ?? 0;
    final txBytes = networkStats['tx_bytes'] ?? 0;

    // Add to history
    _cpuHistory.add(cpuPercent);
    _memoryHistory.add(memoryPercent);
    _networkRxHistory.add(rxBytes / 1024); // Convert to KB
    _networkTxHistory.add(txBytes / 1024); // Convert to KB

    // Keep only the last N data points
    if (_cpuHistory.length > _maxDataPoints) {
      _cpuHistory.removeAt(0);
      _memoryHistory.removeAt(0);
      _networkRxHistory.removeAt(0);
      _networkTxHistory.removeAt(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DockerStatsBloc, DockerStatsState>(
      builder: (context, state) {
          if (state is ContainerStatsLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is ContainerStatsLoaded) {
            final stats = state.stats;
            _updateHistoricalData(stats);
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Real-time Statistics',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // CPU Usage Chart
                  StatsChart(
                    title: 'CPU Usage (%)',
                    spots: _generateCpuSpots(),
                    color: Colors.blue,
                  ),
                  // Memory Usage Chart
                  StatsChart(
                    title: 'Memory Usage (%)',
                    spots: _generateMemorySpots(),
                    color: Colors.green,
                  ),
                  // Network I/O
                  StatsChart(
                    title: 'Network RX (KB)',
                    spots: _generateNetworkRxSpots(),
                    color: Colors.purple,
                  ),
                  StatsChart(
                    title: 'Network TX (KB)',
                    spots: _generateNetworkTxSpots(),
                    color: Colors.orange,
                  ),
                ],
              ),
            );
          } else if (state is ContainerStatsUpdating) {
            // Show the last stats while updating in background
            final stats = state.lastStats;
            _updateHistoricalData(stats);
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Real-time Statistics',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // CPU Usage Chart
                  StatsChart(
                    title: 'CPU Usage (%)',
                    spots: _generateCpuSpots(),
                    color: Colors.blue,
                  ),
                  // Memory Usage Chart
                  StatsChart(
                    title: 'Memory Usage (%)',
                    spots: _generateMemorySpots(),
                    color: Colors.green,
                  ),
                  // Network I/O
                  StatsChart(
                    title: 'Network RX (KB)',
                    spots: _generateNetworkRxSpots(),
                    color: Colors.purple,
                  ),
                  StatsChart(
                    title: 'Network TX (KB)',
                    spots: _generateNetworkTxSpots(),
                    color: Colors.orange,
                  ),
                ],
              ),
            );
          } else if (state is DockerStatsError) {
            // Show charts with last known data even on error
            if (_lastKnownStats != null) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Real-time Statistics (Offline)',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.warning,
                          color: Theme.of(context).colorScheme.error,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // CPU Usage Chart
                    StatsChart(
                      title: 'CPU Usage (%)',
                      spots: _generateCpuSpots(),
                      color: Colors.blue,
                    ),
                    // Memory Usage Chart
                    StatsChart(
                      title: 'Memory Usage (%)',
                      spots: _generateMemorySpots(),
                      color: Colors.green,
                    ),
                    // Network I/O
                    StatsChart(
                      title: 'Network RX (KB)',
                      spots: _generateNetworkRxSpots(),
                      color: Colors.purple,
                    ),
                    StatsChart(
                      title: 'Network TX (KB)',
                      spots: _generateNetworkTxSpots(),
                      color: Colors.orange,
                    ),
                  ],
                ),
              );
            } else {
              return Center(
                child: Text(
                  'Error: ${state.message}',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              );
            }
          }
          // For any other state (DockerStatsInitial, DockerStatsLoading, DockerStatsLoaded),
          // show loading since we should be loading stats
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );
  }

  List<FlSpot> _generateCpuSpots() {
    return _cpuHistory.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();
  }

  List<FlSpot> _generateMemorySpots() {
    return _memoryHistory.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();
  }

  List<FlSpot> _generateNetworkRxSpots() {
    return _networkRxHistory.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();
  }

  List<FlSpot> _generateNetworkTxSpots() {
    return _networkTxHistory.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();
  }
}