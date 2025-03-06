import 'package:flutter/material.dart';
import '../services/monitoring_service.dart';

class ServiceStatusWidget extends StatefulWidget {
  final MonitoringService monitoringService;

  const ServiceStatusWidget({
    super.key,
    required this.monitoringService,
  });

  @override
  State<ServiceStatusWidget> createState() => _ServiceStatusWidgetState();
}

class _ServiceStatusWidgetState extends State<ServiceStatusWidget> {
  @override
  void initState() {
    super.initState();
    widget.monitoringService.addStatusListener(_onStatusChanged);
    widget.monitoringService.startMonitoring();
  }

  @override
  void dispose() {
    widget.monitoringService.removeStatusListener(_onStatusChanged);
    super.dispose();
  }

  void _onStatusChanged(ServiceStatus status) {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      child: _buildStatusIcon(),
      itemBuilder: (context) => _buildStatusMenu(),
    );
  }

  Widget _buildStatusIcon() {
    final status = widget.monitoringService.currentStatus;

    if (status == null) {
      return const CircularProgressIndicator();
    }

    final icon = status.health == ServiceHealth.healthy
        ? Icons.check_circle
        : Icons.warning;
    final color =
        status.health == ServiceHealth.healthy ? Colors.green : Colors.orange;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Icon(icon, color: color),
    );
  }

  List<PopupMenuEntry<String>> _buildStatusMenu() {
    final status = widget.monitoringService.currentStatus;
    if (status == null) return [];

    return [
      _buildServiceStatusHeader(status),
      const PopupMenuDivider(),
      ...widget.monitoringService.unhealthyServices.map(
        (serviceName) => _buildServiceStatusItem(serviceName),
      ),
      const PopupMenuDivider(),
      PopupMenuItem<String>(
        onTap: _refreshStatus,
        child: const Row(
          children: [
            Icon(Icons.refresh),
            SizedBox(width: 8),
            Text('Refresh Status'),
          ],
        ),
      ),
    ];
  }

  PopupMenuItem<String> _buildServiceStatusHeader(ServiceStatus status) {
    return PopupMenuItem<String>(
      enabled: false,
      child: Row(
        children: [
          _buildHealthIcon(status.health),
          const SizedBox(width: 8),
          Text(
            status.health == ServiceHealth.healthy
                ? 'All Systems Operational'
                : '${widget.monitoringService.unhealthyServices.length} Service(s) Degraded',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildServiceStatusItem(String serviceName) {
    return PopupMenuItem<String>(
      enabled: false,
      child: Row(
        children: [
          const Icon(Icons.circle, size: 8, color: Colors.orange),
          const SizedBox(width: 8),
          Text(serviceName),
        ],
      ),
    );
  }

  Widget _buildHealthIcon(ServiceHealth health) {
    switch (health) {
      case ServiceHealth.healthy:
        return const Icon(Icons.check_circle, color: Colors.green);
      case ServiceHealth.degraded:
        return const Icon(Icons.warning, color: Colors.orange);
      case ServiceHealth.unhealthy:
        return const Icon(Icons.error, color: Colors.red);
      case ServiceHealth.unknown:
        return const Icon(Icons.help, color: Colors.grey);
    }
  }

  void _refreshStatus() {
    widget.monitoringService.startMonitoring();
  }
}

// Renamed from ServiceStatus to ServiceStatusIndicator to avoid conflict
class ServiceStatusIndicator extends StatelessWidget {
  final bool isOnline;
  final String serviceName;
  final VoidCallback? onRetry;

  const ServiceStatusIndicator({
    super.key,
    required this.isOnline,
    required this.serviceName,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: isOnline ? Colors.green.withAlpha(26) : Colors.red.withAlpha(26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOnline ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnline ? Icons.check_circle : Icons.error_outline,
            size: 16,
            color: isOnline ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 6),
          Text(
            '$serviceName: ${isOnline ? 'Online' : 'Offline'}',
            style: TextStyle(
              color: isOnline ? Colors.green : Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (!isOnline && onRetry != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onRetry,
              child: const Icon(
                Icons.refresh,
                size: 14,
                color: Colors.red,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ServiceStatusStrip extends StatelessWidget {
  final Map<String, bool> services;
  final VoidCallback? onRetry;

  const ServiceStatusStrip({
    super.key,
    required this.services,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    bool allOnline = services.values.every((status) => status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: allOnline ? Colors.green.shade50 : Colors.red.shade50,
      child: Row(
        children: [
          Icon(
            allOnline ? Icons.check_circle : Icons.warning_amber_rounded,
            size: 16,
            color: allOnline ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              allOnline
                  ? 'All services online'
                  : 'Some services are offline. This may affect functionality.',
              style: TextStyle(
                fontSize: 12,
                color: allOnline ? Colors.green.shade800 : Colors.red.shade800,
              ),
            ),
          ),
          if (!allOnline && onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 24),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}
