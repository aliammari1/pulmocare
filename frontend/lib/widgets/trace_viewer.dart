import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/environment.dart';

class TraceViewer extends StatefulWidget {
  final String traceId;

  const TraceViewer({
    super.key,
    required this.traceId,
  });

  @override
  State<TraceViewer> createState() => _TraceViewerState();
}

class _TraceViewerState extends State<TraceViewer> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _spans = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTraceData();
  }

  Future<void> _loadTraceData() async {
    try {
      final response = await http.get(
        Uri.parse(
            '${EnvironmentConfig.otelCollectorUrl}/v1/traces/${widget.traceId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _spans = List<Map<String, dynamic>>.from(data['spans']);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load trace data');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
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
              onPressed: _loadTraceData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Trace ID: ${widget.traceId}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: _buildTraceTimeline(),
        ),
      ],
    );
  }

  Widget _buildTraceTimeline() {
    // Sort spans by start time
    _spans.sort((a, b) => a['startTime'].compareTo(b['startTime']));

    // Calculate the earliest and latest timestamps
    final firstSpan = _spans.first;
    final lastSpan = _spans.last;
    final startTime =
        DateTime.parse(firstSpan['startTime']).millisecondsSinceEpoch;
    final endTime = DateTime.parse(lastSpan['endTime']).millisecondsSinceEpoch;

    final totalDurationMs = endTime - startTime;

    return ListView.builder(
      itemCount: _spans.length,
      itemBuilder: (context, index) {
        final span = _spans[index];
        final spanStartTime =
            DateTime.parse(span['startTime']).millisecondsSinceEpoch;
        final spanEndTime =
            DateTime.parse(span['endTime']).millisecondsSinceEpoch;

        final startOffset = (spanStartTime - startTime) / totalDurationMs;
        final duration = (spanEndTime - spanStartTime) / totalDurationMs;

        return _buildSpanItem(span, startOffset, duration);
      },
    );
  }

  Widget _buildSpanItem(
      Map<String, dynamic> span, double startOffset, double duration) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            span['name'] ?? 'Unknown Span',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              SizedBox(
                  width: MediaQuery.of(context).size.width * startOffset * 0.8),
              Container(
                width: MediaQuery.of(context).size.width * duration * 0.8,
                height: 24,
                decoration: BoxDecoration(
                  color: _getSpanColor(span),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    '${((span['endTime'] - span['startTime']) / 1000000).toStringAsFixed(2)}ms',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Service: ${span['serviceName'] ?? 'Unknown'}',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSpanColor(Map<String, dynamic> span) {
    final status = span['status']?['code'];
    if (status == 'ERROR') {
      return Colors.red;
    }

    final serviceName = span['serviceName']?.toLowerCase() ?? '';

    if (serviceName.contains('api')) return Colors.blue;
    if (serviceName.contains('db')) return Colors.green;
    if (serviceName.contains('auth')) return Colors.purple;
    if (serviceName.contains('xray')) return Colors.orange;
    if (serviceName.contains('knowledge')) return Colors.teal;

    return Colors.grey;
  }
}
