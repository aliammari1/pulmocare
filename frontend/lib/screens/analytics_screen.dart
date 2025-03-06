import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/xray_provider.dart';
import '../providers/report_provider.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        centerTitle: true,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AnalyticsSummaryCard(),
            SizedBox(height: 16),
            _XRayAnalyticsChart(),
            SizedBox(height: 16),
            _ReportTrendsChart(),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsSummaryCard extends StatelessWidget {
  const _AnalyticsSummaryCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Consumer2<XRayProvider, ReportProvider>(
              builder: (context, xrayProvider, reportProvider, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatCard(
                      title: 'X-Rays Analyzed',
                      value: xrayProvider.history.length.toString(),
                      icon: Icons.medical_services,
                    ),
                    _StatCard(
                      title: 'Reports Generated',
                      value: reportProvider.reports.length.toString(),
                      icon: Icons.description,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }
}

class _XRayAnalyticsChart extends StatelessWidget {
  const _XRayAnalyticsChart();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'X-Ray Analysis Trends',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Consumer<XRayProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: true),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _generateDummyData(), // Replace with real data
                          isCurved: true,
                          color: Theme.of(context).primaryColor,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _generateDummyData() {
    return List.generate(7, (index) {
      return FlSpot(index.toDouble(), index * 2.5);
    });
  }
}

class _ReportTrendsChart extends StatelessWidget {
  const _ReportTrendsChart();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report Analysis Distribution',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Consumer<ReportProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return PieChart(
                    PieChartData(
                      sections: _generateDummyPieData(context),
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _generateDummyPieData(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return [
      PieChartSectionData(
        value: 35,
        title: '35%',
        color: primaryColor,
        radius: 50,
      ),
      PieChartSectionData(
        value: 40,
        title: '40%',
        color: primaryColor.withAlpha(204), // 0.8 * 255 = 204
        radius: 50,
      ),
      PieChartSectionData(
        value: 25,
        title: '25%',
        color: primaryColor.withAlpha(153), // 0.6 * 255 = 153
        radius: 50,
      ),
    ];
  }
}
