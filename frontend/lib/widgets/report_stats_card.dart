import 'package:flutter/material.dart';
import '../models/medical_report.dart';

class ReportStatsCard extends StatelessWidget {
  final List<MedicalReport> reports;

  const ReportStatsCard({
    super.key,
    required this.reports,
  });

  @override
  Widget build(BuildContext context) {
    final totalReports = reports.length;
    final reportsThisWeek = _getReportsInLastDays(7);
    final reportsThisMonth = _getReportsInLastDays(30);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatItem(
                  context,
                  'Total Reports',
                  totalReports,
                  Icons.description,
                  Colors.blue,
                ),
                _buildStatItem(
                  context,
                  'This Week',
                  reportsThisWeek,
                  Icons.calendar_today,
                  Colors.green,
                ),
                _buildStatItem(
                  context,
                  'This Month',
                  reportsThisMonth,
                  Icons.date_range,
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    int value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  int _getReportsInLastDays(int days) {
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: days));
    return reports.where((report) => report.createdAt.isAfter(cutoff)).length;
  }
}
