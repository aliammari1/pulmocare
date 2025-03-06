import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/environment.dart';
import '../widgets/trace_viewer.dart';
import 'dart:async';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;
  Map<String, dynamic> _servicesHealth = {};
  List<Map<String, dynamic>> _recentTraces = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 10), (_) => _loadData());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Load services health
      final serviceRegistry = await http.get(
        Uri.parse('${EnvironmentConfig.apiBaseUrl}/v1/catalog/services'),
      );

      if (serviceRegistry.statusCode == 200) {
        final servicesMap =
            json.decode(serviceRegistry.body) as Map<String, dynamic>;
        final Map<String, dynamic> health = {};

        // Fetch details for each service
        for (final serviceName in servicesMap.keys) {
          if (serviceName == 'consul') {
            continue; // Skip the consul service itself
          }

          final serviceHealth = await http.get(
            Uri.parse(
                '${EnvironmentConfig.apiBaseUrl}/v1/health/service/$serviceName'),
          );

          if (serviceHealth.statusCode == 200) {
            final instances = json.decode(serviceHealth.body) as List;
            final bool isHealthy = instances.any((i) => i['Checks'].any(
                (check) =>
                    check['ServiceName'] == serviceName &&
                    check['Status'] == 'passing'));

            health[serviceName.toLowerCase()] = {
              'status': isHealthy ? 'UP' : 'DOWN',
              'instanceCount': instances.length,
            };
          }
        }

        // Load recent traces if tracing is enabled
        List<Map<String, dynamic>> traces = [];
        if (EnvironmentConfig.enableTracing) {
          final tracesResponse = await http.get(
            Uri.parse(
                '${EnvironmentConfig.otelCollectorUrl}/v1/traces?limit=10'),
          );

          if (tracesResponse.statusCode == 200) {
            traces = List<Map<String, dynamic>>.from(
                json.decode(tracesResponse.body)['traces']);
          }
        }

        setState(() {
          _servicesHealth = health;
          _recentTraces = traces;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildServiceHealthCard(
      String serviceName, Map<String, dynamic> health) {
    final isUp = health['status'] == 'UP';

    return Card(
      child: ListTile(
        leading: Icon(
          isUp ? Icons.check_circle : Icons.error,
          color: isUp ? Colors.green : Colors.red,
        ),
        title: Text(
          serviceName.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Instances: ${health['instanceCount']}'),
        trailing: health['status'] == 'UP'
            ? const Text(
                'Healthy',
                style: TextStyle(color: Colors.green),
              )
            : const Text(
                'Unhealthy',
                style: TextStyle(color: Colors.red),
              ),
      ),
    );
  }

  Widget _buildTracesTab() {
    if (!EnvironmentConfig.enableTracing) {
      return const Center(
        child: Text('Tracing is disabled in this environment'),
      );
    }

    return ListView.builder(
      itemCount: _recentTraces.length,
      itemBuilder: (context, index) {
        final trace = _recentTraces[index];
        return ExpansionTile(
          title: Text('Trace ${trace['traceId']}'),
          subtitle: Text(
            '${trace['spans'].length} spans - ${DateTime.parse(trace['startTime']).toLocal()}',
          ),
          children: [
            SizedBox(
              height: 300,
              child: TraceViewer(traceId: trace['traceId']),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Monitoring'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Services'),
            Tab(text: 'Traces'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Services Tab
          RefreshIndicator(
            onRefresh: _loadData,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                ..._servicesHealth.entries.map(
                  (entry) => _buildServiceHealthCard(entry.key, entry.value),
                ),
              ],
            ),
          ),
          // Traces Tab
          RefreshIndicator(
            onRefresh: _loadData,
            child: _buildTracesTab(),
          ),
        ],
      ),
    );
  }
}
