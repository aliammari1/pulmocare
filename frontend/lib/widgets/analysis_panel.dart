import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/xray_provider.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/xray_quality_metrics.dart';

class AnalysisPanel extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final VoidCallback? onReset;

  const AnalysisPanel({
    super.key,
    required this.child,
    required this.isLoading,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: isLoading,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Analysis Results',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (onReset != null)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    onReset?.call();
                    context.read<XRayProvider>().clearAnalysis();
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class ErrorDisplay extends StatelessWidget {
  final String error;

  const ErrorDisplay({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Analysis Error',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<XRayProvider>().reset(),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

class AnalysisResults extends StatelessWidget {
  final Map<String, dynamic> analysis;

  const AnalysisResults({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    final findings = analysis['analysis']['findings'] as List;
    final technicalDetails = analysis['technical_details'];
    final summary = analysis['summary'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analysis Results',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),

          // Summary Section
          SummarySection(summary: summary),
          const SizedBox(height: 24),

          // Findings Section
          FindingsSection(findings: findings),
          const SizedBox(height: 24),

          // Technical Details
          TechnicalSection(details: technicalDetails),

          if (analysis['knowledge_context'] != null) ...[
            const SizedBox(height: 24),
            KnowledgeContextSection(
                knowledgeData: analysis['knowledge_context']),
          ],
        ],
      ),
    );
  }
}

class SummarySection extends StatelessWidget {
  final Map<String, dynamic> summary;

  const SummarySection({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final riskColor = _getRiskColor(summary['risk_level']);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.summarize),
                const SizedBox(width: 8),
                Text(
                  'Summary',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(summary['main_findings']),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.circle, size: 12, color: riskColor),
                const SizedBox(width: 8),
                Text(
                  'Risk Level: ${summary['risk_level'].toUpperCase()}',
                  style:
                      TextStyle(color: riskColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(summary['follow_up']),
          ],
        ),
      ),
    );
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'moderate':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class FindingsSection extends StatelessWidget {
  final List findings;

  const FindingsSection({super.key, required this.findings});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medical_information),
                const SizedBox(width: 8),
                Text(
                  'Findings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: findings.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final finding = findings[index];
                return FindingTile(finding: finding);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class FindingTile extends StatelessWidget {
  final Map<String, dynamic> finding;

  const FindingTile({super.key, required this.finding});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(finding['condition']),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Severity: ${finding['severity']}'),
          LinearProgressIndicator(
            value: finding['probability'],
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              _getSeverityColor(finding['severity']),
            ),
          ),
          Text(
            'Confidence: ${(finding['confidence_score']).toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red[900]!;
      case 'severe':
        return Colors.red;
      case 'moderate':
        return Colors.orange;
      case 'mild':
        return Colors.yellow[700]!;
      default:
        return Colors.grey;
    }
  }
}

class TechnicalSection extends StatelessWidget {
  final Map<String, dynamic> details;

  const TechnicalSection({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics),
                const SizedBox(width: 8),
                Text(
                  'Technical Assessment',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
                'Overall Quality: ${details['overall_quality'].toUpperCase()}'),
            const SizedBox(height: 16),
            XRayQualityMetrics(metrics: details['quality_metrics']),
          ],
        ),
      ),
    );
  }
}

class KnowledgeContextSection extends StatelessWidget {
  final List<Map<String, dynamic>> knowledgeContext;

  KnowledgeContextSection({
    super.key,
    required List<dynamic> knowledgeData,
  }) : knowledgeContext =
            List<Map<String, dynamic>>.from(knowledgeData, growable: false);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.library_books),
                const SizedBox(width: 8),
                Text(
                  'Medical Knowledge',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: knowledgeContext.length,
              itemBuilder: (context, index) {
                final item = knowledgeContext[index];
                return ExpansionTile(
                  title: Text(item['condition'] as String),
                  children: [
                    for (final ref in (item['references'] as List))
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(ref['content'] as String),
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

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.upload_file, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Upload an X-ray image to begin analysis'),
        ],
      ),
    );
  }
}
