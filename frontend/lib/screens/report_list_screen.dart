import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_saver/file_saver.dart';
import '../providers/report_provider.dart';
import '../services/snackbar_service.dart';
import '../services/navigation_service.dart';
import '../widgets/loading_overlay.dart';
import 'report_editor_screen.dart';

class ReportListScreen extends StatefulWidget {
  const ReportListScreen({super.key});

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    if (!mounted) return;
    setState(() {
    });

    try {
      await context.read<ReportProvider>().loadReports();
    } catch (e) {
      if (!mounted) return;
      setState(() {
      });
    } finally {
      if (!mounted) return;
      setState(() {
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Reports'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ReportProvider>().searchReports('');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _SearchBar(),
          const Divider(),
          Expanded(
            child: Consumer<ReportProvider>(
              builder: (context, provider, _) {
                return LoadingOverlay(
                  isLoading: provider.isLoading,
                  child: _buildReportList(context, provider),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ReportEditorScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildReportList(BuildContext context, ReportProvider provider) {
    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              provider.error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                provider.clearError();
                provider.searchReports('');
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (provider.reports.isEmpty) {
      return const Center(
        child: Text('No reports found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: provider.reports.length,
      itemBuilder: (context, index) {
        final report = provider.reports[index];
        return Card(
          child: ListTile(
            title: Text(report['title'] ?? 'Untitled Report'),
            subtitle: Text(
              report['summary'] ?? 'No summary available',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: _buildReportStatus(report['status']),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReportEditorScreen(report: report),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildReportStatus(String? status) {
    if (status == null) return const SizedBox.shrink();

    Color color;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'pending':
        color = Colors.orange;
        icon = Icons.access_time;
        break;
      case 'draft':
        color = Colors.grey;
        icon = Icons.edit;
        break;
      default:
        color = Colors.blue;
        icon = Icons.info;
    }

    return Icon(icon, color: color);
  }
}

class _SearchBar extends StatefulWidget {
  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<ReportProvider>().searchReports(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search reports...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              _onSearchChanged('');
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }
}

class ReportListItem extends StatelessWidget {
  final Map<String, dynamic> report;

  const ReportListItem({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(report['id'] ?? ''),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Report'),
            content: const Text('Are you sure you want to delete this report?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        try {
          final provider = Provider.of<ReportProvider>(context, listen: false);
          await provider.deleteReport(report['id']);
          if (provider.error != null && provider.error!.isNotEmpty) {
            SnackbarService.showError(
                context, 'Failed to delete report: ${provider.error}');
          } else {
            SnackbarService.showSuccess(context, 'Report deleted');
          }
        } catch (e) {
          SnackbarService.showError(context, 'Failed to delete report: $e');
        }
      },
      child: Hero(
        tag: 'report_${report['id']}',
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: InkWell(
            onTap: () => _navigateToEditor(context, report),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          report['title'] ?? 'Untitled Report',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'share',
                            child: Row(
                              children: [
                                Icon(Icons.share),
                                SizedBox(width: 8),
                                Text('Share'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'export',
                            child: Row(
                              children: [
                                Icon(Icons.download),
                                SizedBox(width: 8),
                                Text('Export'),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) =>
                            _handleMenuAction(context, value, report),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last updated: ${report['updatedAt']}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (report['content']?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 8),
                    Text(
                      (report['content'] as String).length > 100
                          ? '${(report['content'] as String).substring(0, 100)}...'
                          : report['content'] as String,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToEditor(BuildContext context, Map<String, dynamic> report) {
    NavigationService.push(
      context,
      ReportEditorScreen(report: report),
    );
  }

  void _handleMenuAction(
      BuildContext context, String action, Map<String, dynamic> report) async {
    switch (action) {
      case 'edit':
        _navigateToEditor(context, report);
        break;
      case 'share':
        // Share functionality
        break;
      case 'export':
        final provider = Provider.of<ReportProvider>(context, listen: false);
        final bytes = await provider.exportReport(report['id'], format: 'pdf');

        if (bytes != null) {
          try {
            await FileSaver.instance.saveFile(
              name: 'report_${report['id']}.pdf',
              bytes: bytes,
              ext: 'pdf',
              mimeType: MimeType.pdf,
            );

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Report exported successfully')),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error exporting report: $e')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to export report')),
          );
        }
    }
  }
}

class ReportSearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> reports;

  ReportSearchDelegate(this.reports);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final results = reports.where((report) {
      return (report['title'] ?? '')
              .toLowerCase()
              .contains(query.toLowerCase()) ||
          (report['content'] ?? '').toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final report = results[index];
        return ListTile(
          title: Text(
            report['title'] ?? 'Untitled',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            report['content'] ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            close(context, null);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReportEditorScreen(report: report),
              ),
            );
          },
        );
      },
    );
  }
}
