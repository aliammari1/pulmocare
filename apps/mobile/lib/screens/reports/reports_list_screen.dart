import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/report.dart';
import '../../services/api_service.dart';
import '../../services/auth_view_model.dart';
import '../create_report_screen.dart';
import '../../theme/app_theme.dart';
import 'report_detail_screen.dart';

class ReportsListScreen extends StatefulWidget {
  const ReportsListScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends State<ReportsListScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _search = TextEditingController();

  List<Report> _reports = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final reports = await _api.getReports(search: _search.text);
      if (!mounted) return;
      setState(() {
        _reports = reports;
        _loading = false;
      });
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _errorMessage(error);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();
    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(title: const Text('Medical reports')),
      body: body,
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.description_outlined, size: 52),
              const SizedBox(height: 14),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: _loadReports,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReports,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_canCreateReport(context)) ...[
            FilledButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateReportScreen()),
                );
                if (mounted) await _loadReports();
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create medical report'),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _loadReports(),
            decoration: InputDecoration(
              hintText: 'Search reports',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                tooltip: 'Search',
                onPressed: _loadReports,
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (_reports.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 56),
              child: Column(
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 54,
                    color: AppTheme.primary,
                  ),
                  SizedBox(height: 14),
                  Text('No reports were returned by the reports service.'),
                ],
              ),
            )
          else
            for (final report in _reports)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE6F2F4),
                    child: Icon(
                      Icons.description_outlined,
                      color: AppTheme.primary,
                    ),
                  ),
                  title: Text(report.title),
                  subtitle: Text(
                    [
                      if (report.patientId.isNotEmpty)
                        'Patient ${_shortId(report.patientId)}',
                      if (report.createdAt.millisecondsSinceEpoch > 0)
                        DateFormat.yMMMd().format(report.createdAt.toLocal()),
                    ].join(' • '),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: report.id.isEmpty
                      ? null
                      : () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ReportDetailScreen(reportId: report.id),
                            ),
                          );
                          await _loadReports();
                        },
                ),
              ),
        ],
      ),
    );
  }

  static bool _canCreateReport(BuildContext context) {
    final role = context.read<AuthViewModel>().userRole;
    return role == 'doctor' || role == 'radiologist' || role == 'admin';
  }

  static String _shortId(String value) =>
      value.length <= 8 ? value : value.substring(0, 8);

  static String _errorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['detail'] is String) {
      return data['detail'] as String;
    }
    return 'Unable to load reports from the server.';
  }
}
