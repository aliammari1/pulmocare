import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/report_provider.dart';
import '../widgets/loading_overlay.dart';

class ReportEditorScreen extends StatefulWidget {
  final Map<String, dynamic>? report;

  const ReportEditorScreen({super.key, this.report});

  @override
  State<ReportEditorScreen> createState() => _ReportEditorScreenState();
}

class _ReportEditorScreenState extends State<ReportEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysis;

  @override
  void initState() {
    super.initState();
    if (widget.report != null) {
      _titleController.text = widget.report!['title'] ?? '';
      _contentController.text = widget.report!['content'] ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _analyzeReport() async {
    if (_contentController.text.isEmpty) return;

    setState(() => _isAnalyzing = true);

    try {
      final provider = context.read<ReportProvider>();
      final analysis = await provider.analyzeReport(_contentController.text);
      setState(() {
        _isAnalyzing = false;
        _analysis = analysis;
      });
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error analyzing report: $e')),
        );
      }
    }
  }

  Future<void> _saveReport() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final provider = context.read<ReportProvider>();
      final report = {
        'id': widget.report?['id'],
        'title': _titleController.text,
        'content': _contentController.text,
        'analysis': _analysis,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (widget.report == null) {
        await provider.createReport(report);
      } else {
        await provider.updateReport(report);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report saved successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving report: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.report == null ? 'New Report' : 'Edit Report'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveReport,
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isAnalyzing,
        message: 'Analyzing report...',
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: 'Report Content',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 10,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter report content';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _analyzeReport,
                      icon: const Icon(Icons.analytics),
                      label: const Text('Analyze Report'),
                    ),
                    if (_analysis != null) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Analysis Results',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildAnalysisResults(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisResults() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_analysis!['entities'] != null) ...[
              const Text(
                'Medical Entities',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var entity in _analysis!['entities'])
                    Chip(
                      label: Text(entity['text']),
                      backgroundColor: _getEntityColor(entity['type']),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            if (_analysis!['suggestions'] != null) ...[
              const Text(
                'Suggestions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  for (var suggestion in _analysis!['suggestions'])
                    ListTile(
                      leading: const Icon(Icons.lightbulb_outline),
                      title: Text(suggestion),
                      dense: true,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getEntityColor(String type) {
    switch (type.toLowerCase()) {
      case 'condition':
        return Colors.red.shade100;
      case 'treatment':
        return Colors.green.shade100;
      case 'medication':
        return Colors.blue.shade100;
      case 'test':
        return Colors.orange.shade100;
      default:
        return Colors.grey.shade100;
    }
  }
}
