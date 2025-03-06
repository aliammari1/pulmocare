import 'package:flutter/material.dart';

class XRayQualityMetrics extends StatelessWidget {
  final Map<String, dynamic> metrics;

  const XRayQualityMetrics({
    super.key,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Image Quality Metrics',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        _buildMetricGrid(context),
      ],
    );
  }

  Widget _buildMetricGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      childAspectRatio: 3.0,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildMetricItem(
          context,
          'Contrast',
          _parseMetricValue(metrics['contrast']),
          _getQualityColor(_parseMetricValue(metrics['contrast'])),
        ),
        _buildMetricItem(
          context,
          'Sharpness',
          _parseMetricValue(metrics['sharpness']),
          _getQualityColor(_parseMetricValue(metrics['sharpness'])),
        ),
        _buildMetricItem(
          context,
          'Exposure',
          _parseMetricValue(metrics['exposure']),
          _getQualityColor(_parseMetricValue(metrics['exposure'])),
        ),
        _buildMetricItem(
          context,
          'Positioning',
          _parseMetricValue(metrics['positioning']),
          _getQualityColor(_parseMetricValue(metrics['positioning'])),
        ),
        _buildMetricItem(
          context,
          'Noise Level',
          _parseMetricValue(metrics['noise_level']),
          _getQualityColor(_parseMetricValue(metrics['noise_level'])),
        ),
      ],
    );
  }

  double _parseMetricValue(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Widget _buildMetricItem(
    BuildContext context,
    String label,
    double value,
    Color color,
  ) {
    return Card(
      elevation: 0,
      color: color.withAlpha(38), // Replace withOpacity(0.15)
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.circle,
              size: 12,
              color: color,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getQualityColor(double quality) {
    if (quality >= 0.8) {
      return Colors.green.withAlpha(230); // Replace withOpacity(0.9)
    } else if (quality >= 0.6) {
      return Colors.orange.withAlpha(230);
    } else {
      return Colors.red.withAlpha(230);
    }
  }
}
