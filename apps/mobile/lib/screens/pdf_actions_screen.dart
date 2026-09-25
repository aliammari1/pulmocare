import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../models/ordonnance.dart';
import '../services/auth_view_model.dart';
import '../services/ordonnance_viewmodel.dart';
import '../theme/app_theme.dart';

class PdfActionsScreen extends StatefulWidget {
  const PdfActionsScreen({super.key});

  @override
  State<PdfActionsScreen> createState() => _PdfActionsScreenState();
}

class _PdfActionsScreenState extends State<PdfActionsScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<OrdonnanceViewModel>();
    final prescription = viewModel.ordonnance;
    if (prescription == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Prescription')),
        body: const Center(child: Text('No prescription is selected.')),
      );
    }

    final role = context.watch<AuthViewModel>().userRole;
    final canEmail = role == 'doctor' || role == 'admin';

    return Scaffold(
      appBar: AppBar(title: const Text('Prescription')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _PrescriptionSummary(prescription: prescription),
          const SizedBox(height: 22),
          Text(
            'Actions',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          _ActionCard(
            icon: Icons.picture_as_pdf_outlined,
            title: 'Preview PDF',
            subtitle: 'Open the canonical PulmoCare prescription PDF.',
            onTap: _busy ? null : () => _preview(viewModel),
          ),
          const SizedBox(height: 10),
          _ActionCard(
            icon: Icons.ios_share_outlined,
            title: 'Share or save PDF',
            subtitle: 'Use the device share sheet to save or send a copy.',
            onTap: _busy ? null : () => _share(viewModel),
          ),
          if (canEmail) ...[
            const SizedBox(height: 10),
            _ActionCard(
              icon: Icons.mail_outline_rounded,
              title: 'Email to patient',
              subtitle: 'Prepare an email with the prescription PDF attached.',
              onTap: _busy ? null : () => _email(viewModel),
            ),
          ],
          if (_busy) ...[
            const SizedBox(height: 18),
            const LinearProgressIndicator(),
          ],
          if (viewModel.errorMessage case final error?) ...[
            const SizedBox(height: 18),
            Text(
              error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }

  Future<Uint8List?> _loadPdf(OrdonnanceViewModel viewModel) async {
    final prescription = viewModel.ordonnance;
    if (prescription == null) return null;

    final id = prescription.id;
    if (id != null && id.isNotEmpty) {
      final serverPdf = await viewModel.viewOrdonnancePdf(id);
      if (serverPdf != null) return serverPdf;
    }
    return prescription.generatePdf();
  }

  Future<void> _preview(OrdonnanceViewModel viewModel) async {
    await _run(() async {
      final bytes = await _loadPdf(viewModel);
      if (bytes == null) throw StateError('Prescription PDF unavailable');
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    });
  }

  Future<void> _share(OrdonnanceViewModel viewModel) async {
    await _run(() async {
      final bytes = await _loadPdf(viewModel);
      if (bytes == null) throw StateError('Prescription PDF unavailable');
      final id = viewModel.ordonnance?.id ?? 'draft';
      await Printing.sharePdf(bytes: bytes, filename: 'prescription_$id.pdf');
    });
  }

  Future<void> _email(OrdonnanceViewModel viewModel) async {
    final prescription = viewModel.ordonnance;
    if (prescription == null) return;

    await _run(() async {
      final contact = await viewModel.getPatientEmail(prescription.patientId);
      final email = contact['email']?.trim() ?? '';
      if (email.isEmpty) {
        throw StateError('No email is available for this patient.');
      }

      final bytes = await _loadPdf(viewModel);
      if (bytes == null) throw StateError('Prescription PDF unavailable');

      final sent = await viewModel.sendOrdonnancePdfToEmail(
        email,
        bytes,
        prescription.patientId,
      );
      if (!sent) {
        throw StateError(
          viewModel.errorMessage ?? 'Unable to prepare the email.',
        );
      }
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _PrescriptionSummary extends StatelessWidget {
  const _PrescriptionSummary({required this.prescription});

  final Ordonnance prescription;

  @override
  Widget build(BuildContext context) {
    final patient = prescription.patientName.trim().isNotEmpty
        ? prescription.patientName
        : prescription.patientId;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.medication_outlined, size: 34, color: Colors.white),
          const SizedBox(height: 14),
          Text(
            patient,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat.yMMMd().format(prescription.date.toLocal()),
            style: const TextStyle(color: Colors.white70),
          ),
          if (prescription.diagnosis.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              prescription.diagnosis,
              style: const TextStyle(color: Colors.white),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            '${prescription.medicaments.length} medication${prescription.medicaments.length == 1 ? '' : 's'}',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: AppTheme.primary),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
