import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/ordonnance.dart';
import '../services/auth_view_model.dart';
import '../services/ordonnance_viewmodel.dart';
import '../theme/app_theme.dart';
import 'pdf_actions_screen.dart';

class OrdonnancesListScreen extends StatefulWidget {
  const OrdonnancesListScreen({super.key});

  @override
  State<OrdonnancesListScreen> createState() => _OrdonnancesListScreenState();
}

class _OrdonnancesListScreenState extends State<OrdonnancesListScreen> {
  final _dateFormat = DateFormat.yMMMd().add_jm();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthViewModel>();
    final userId = auth.userId;
    if (userId == null || userId.isEmpty) return;
    await context.read<OrdonnanceViewModel>().loadMedecinOrdonnances(userId);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final canCreate = auth.userRole == 'doctor' || auth.userRole == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescriptions'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Consumer<OrdonnanceViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading &&
              (viewModel.medecinOrdonnances?.isEmpty ?? true)) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.errorMessage != null &&
              (viewModel.medecinOrdonnances?.isEmpty ?? true)) {
            return _StateMessage(
              icon: Icons.cloud_off_outlined,
              title: 'Prescriptions unavailable',
              message: viewModel.errorMessage!,
              actionLabel: 'Retry',
              onAction: _load,
            );
          }

          final items = viewModel.medecinOrdonnances ?? const [];
          if (items.isEmpty) {
            return _StateMessage(
              icon: Icons.medication_outlined,
              title: 'No prescriptions yet',
              message: canCreate
                  ? 'Create a prescription for a patient when medication is required.'
                  : 'Prescriptions issued to your account will appear here.',
              actionLabel: canCreate ? 'Create prescription' : 'Refresh',
              onAction: canCreate
                  ? () => Navigator.pushNamed(context, '/new-ordonnance')
                  : _load,
            );
          }

          return RefreshIndicator(
            onRefresh: _load,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, index) {
                final raw = items[index];
                final prescription = Ordonnance.fromJson(raw);
                return _PrescriptionCard(
                  prescription: prescription,
                  raw: raw,
                  dateFormat: _dateFormat,
                  onTap: () async {
                    viewModel.setCurrentOrdonnance(prescription);
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PdfActionsScreen(),
                      ),
                    );
                    if (mounted) await _load();
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, '/new-ordonnance'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New prescription'),
            )
          : null,
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  const _PrescriptionCard({
    required this.prescription,
    required this.raw,
    required this.dateFormat,
    required this.onTap,
  });

  final Ordonnance prescription;
  final Map<String, dynamic> raw;
  final DateFormat dateFormat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final patientLabel = prescription.patientName.trim().isNotEmpty
        ? prescription.patientName
        : 'Patient ${_shortId(prescription.patientId)}';
    final diagnosis = prescription.diagnosis.trim();

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.medication_outlined, color: AppTheme.primary),
        ),
        title: Text(patientLabel),
        subtitle: Text(
          [
            dateFormat.format(prescription.date.toLocal()),
            if (diagnosis.isNotEmpty) diagnosis,
            '${prescription.medicaments.length} medication${prescription.medicaments.length == 1 ? '' : 's'}',
          ].join(' • '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }

  static String _shortId(String value) =>
      value.length <= 8 ? value : value.substring(0, 8);
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              Icon(icon, size: 58, color: AppTheme.primary),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ),
        ),
      ),
    );
  }
}
