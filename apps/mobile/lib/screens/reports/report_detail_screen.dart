import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/report.dart';
import '../../services/api_service.dart';
import '../../services/auth_view_model.dart';

class ReportDetailScreen extends StatefulWidget {
  const ReportDetailScreen({super.key, required this.reportId});

  final String reportId;

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  final ApiService _api = ApiService();
  Report? _report;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final report = await _api.getReportById(widget.reportId);
      if (!mounted) return;
      setState(() {
        _report = report;
        _loading = false;
      });
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        final data = error.response?.data;
        _error = data is Map && data['detail'] is String
            ? data['detail'] as String
            : 'Unable to load this report.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report'),
        actions: [
          if (_report != null && _canManage(context)) ...[
            IconButton(
              tooltip: 'Edit report',
              onPressed: _edit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Delete report',
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _report == null
          ? const Center(child: Text('Report not found'))
          : _content(_report!),
    );
  }

  Widget _content(Report report) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(report.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            if (report.createdAt.millisecondsSinceEpoch > 0)
              Text(
                DateFormat.yMMMd().add_jm().format(report.createdAt.toLocal()),
              ),
            if (report.patientId.isNotEmpty)
              Text('Patient: ${report.patientId}'),
            if (report.doctorId.isNotEmpty)
              Text('Provider: ${report.doctorId}'),
          ],
        ),
        const SizedBox(height: 22),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: SelectableText(
              report.content.isEmpty
                  ? 'This report does not contain narrative content.'
                  : report.content,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(height: 1.55),
            ),
          ),
        ),
        if (report.additionalData case final extra?) ...[
          const SizedBox(height: 18),
          Text(
            'Additional data',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  for (final entry in extra.entries)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              entry.key.replaceAll('_', ' '),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: Text(entry.value?.toString() ?? ''),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  bool _canManage(BuildContext context) {
    final role = context.read<AuthViewModel>().userRole;
    return role == 'doctor' || role == 'radiologist' || role == 'admin';
  }

  Future<void> _edit() async {
    final report = _report;
    if (report == null) return;

    final formKey = GlobalKey<FormState>();
    final title = TextEditingController(text: report.title);
    final content = TextEditingController(text: report.content);
    String? localError;

    final updated = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit report'),
          content: SizedBox(
            width: 620,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: title,
                      decoration: const InputDecoration(
                        labelText: 'Report title',
                      ),
                      validator: (value) => (value?.trim().length ?? 0) < 3
                          ? 'Enter a report title.'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: content,
                      minLines: 8,
                      maxLines: 18,
                      decoration: const InputDecoration(
                        labelText: 'Clinical report',
                        alignLabelWithHint: true,
                      ),
                      validator: (value) => (value?.trim().length ?? 0) < 3
                          ? 'Enter report content.'
                          : null,
                    ),
                    if (localError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        localError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  await _api.updateReport(report.id, {
                    'title': title.text.trim(),
                    'content': content.text.trim(),
                  });
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext, true);
                  }
                } on DioException catch (error) {
                  final data = error.response?.data;
                  setState(() {
                    localError = data is Map && data['detail'] is String
                        ? data['detail'] as String
                        : 'Unable to update the report.';
                  });
                }
              },
              child: const Text('Save changes'),
            ),
          ],
        ),
      ),
    );

    title.dispose();
    content.dispose();

    if (updated == true && mounted) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Report updated.')));
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete report?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _api.deleteReport(widget.reportId);
      if (mounted) Navigator.pop(context);
    } on DioException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to delete the report.')),
      );
    }
  }
}
