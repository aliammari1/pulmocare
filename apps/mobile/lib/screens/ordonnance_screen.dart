import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/medicament.dart';
import '../models/ordonnance.dart';
import '../models/patient_directory_entry.dart';
import '../services/auth_view_model.dart';
import '../services/ordonnance_viewmodel.dart';
import '../theme/app_theme.dart';
import '../widgets/cachet_medecin.dart';
import '../widgets/patient_picker_dialog.dart';
import '../widgets/signature_pad.dart';
import 'pdf_actions_screen.dart';

class OrdonnanceScreen extends StatefulWidget {
  const OrdonnanceScreen({super.key});

  @override
  State<OrdonnanceScreen> createState() => _OrdonnanceScreenState();
}

class _OrdonnanceScreenState extends State<OrdonnanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientId = TextEditingController();
  final _patientName = TextEditingController();
  final _clinic = TextEditingController();
  final _specialty = TextEditingController();
  final _diagnosis = TextEditingController();
  final _instructions = TextEditingController();
  final _search = TextEditingController();

  final List<Medicament> _medications = [];
  Uint8List? _signature;
  Uint8List? _stamp;
  Timer? _searchDebounce;
  bool _searching = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthViewModel>();
      if (_specialty.text.isEmpty) {
        _specialty.text = auth.currentDoctor?.specialty ?? '';
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _patientId.dispose();
    _patientName.dispose();
    _clinic.dispose();
    _specialty.dispose();
    _diagnosis.dispose();
    _instructions.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _selectPatient() async {
    final patient = await showDialog<PatientDirectoryEntry>(
      context: context,
      builder: (_) => const PatientPickerDialog(),
    );
    if (patient == null || !mounted) return;

    setState(() {
      _patientId.text = patient.id;
      _patientName.text = patient.name;
    });
  }

  void _searchMedications(String value) {
    _searchDebounce?.cancel();
    final query = value.trim();
    if (query.length < 2) {
      context.read<OrdonnanceViewModel>().clearResults();
      if (_searching) setState(() => _searching = false);
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      setState(() => _searching = true);
      await context.read<OrdonnanceViewModel>().fetchMedicaments(query);
      if (mounted) setState(() => _searching = false);
    });
  }

  Future<void> _addMedication(Medicament source) async {
    final edited = await showDialog<Medicament>(
      context: context,
      builder: (_) => _MedicationEditorDialog(medication: source),
    );
    if (edited == null || !mounted) return;

    setState(() {
      final existing = _medications.indexWhere(
        (item) => item.name == edited.name,
      );
      if (existing >= 0) {
        _medications[existing] = edited;
      } else {
        _medications.add(edited);
      }
      _search.clear();
      context.read<OrdonnanceViewModel>().clearResults();
    });
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    final auth = context.read<AuthViewModel>();
    final providerId = auth.userId;
    final role = auth.userRole;
    if (providerId == null ||
        providerId.isEmpty ||
        (role != 'doctor' && role != 'admin')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A doctor account is required to prescribe medication.',
          ),
        ),
      );
      return;
    }
    if (_medications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one medication.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final prescription = Ordonnance(
        patientId: _patientId.text,
        patientName: _patientName.text,
        medecinId: providerId,
        doctorName: auth.displayName ?? auth.userEmail ?? 'Doctor',
        clinique: _clinic.text,
        specialite: _specialty.text,
        diagnosis: _diagnosis.text,
        instructions: _instructions.text,
        date: DateTime.now(),
        medicaments: List.unmodifiable(_medications),
        signature: _signature,
        cachet: _stamp,
      );

      final viewModel = context.read<OrdonnanceViewModel>();
      final created = await viewModel.createOrdonnance(prescription);
      if (!mounted) return;

      if (!created) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              viewModel.errorMessage ?? 'Unable to create prescription.',
            ),
          ),
        );
        return;
      }

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PdfActionsScreen()),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<OrdonnanceViewModel>();
    final results = viewModel.searchResults ?? const <Medicament>[];

    return Scaffold(
      appBar: AppBar(title: const Text('New prescription')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            _SectionCard(
              title: 'Patient',
              icon: Icons.person_outline_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: _saving ? null : _selectPatient,
                    icon: const Icon(Icons.person_search_rounded),
                    label: Text(
                      _patientId.text.isEmpty
                          ? 'Select patient'
                          : 'Change patient',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _patientName,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Patient name',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (value) => (value?.trim().isEmpty ?? true)
                        ? 'Select a patient.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _patientId,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Patient ID',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (value) => (value?.trim().isEmpty ?? true)
                        ? 'Select a patient.'
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Clinical context',
              icon: Icons.note_alt_outlined,
              child: Column(
                children: [
                  TextFormField(
                    controller: _diagnosis,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Diagnosis / indication',
                      alignLabelWithHint: true,
                    ),
                    validator: (value) => (value?.trim().length ?? 0) < 3
                        ? 'Enter the clinical indication.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _instructions,
                    minLines: 2,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'General instructions',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _clinic,
                    decoration: const InputDecoration(
                      labelText: 'Clinic (optional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _specialty,
                    decoration: const InputDecoration(
                      labelText: 'Specialty (optional)',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Medications',
              icon: Icons.medication_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _search,
                    onChanged: _searchMedications,
                    decoration: InputDecoration(
                      hintText: 'Search OpenFDA by brand or generic name',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searching
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                  if (results.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 260),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: results.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, index) {
                          final item = results[index];
                          return ListTile(
                            title: Text(item.name),
                            subtitle: Text(
                              [
                                if ((item.usage ?? '').isNotEmpty) item.usage!,
                                if ((item.dosage ?? '').isNotEmpty)
                                  item.dosage!,
                              ].join(' • '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: const Icon(Icons.add_circle_outline),
                            onTap: () => _addMedication(item),
                          );
                        },
                      ),
                    ),
                  ],
                  if (_medications.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    for (final medication in _medications)
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(medication.name),
                          subtitle: Text(
                            [
                              if ((medication.dosage ?? '').isNotEmpty)
                                medication.dosage!,
                              if ((medication.posologie ?? '').isNotEmpty)
                                medication.posologie!,
                            ].join(' • '),
                          ),
                          onTap: () => _addMedication(medication),
                          trailing: IconButton(
                            tooltip: 'Remove medication',
                            onPressed: () =>
                                setState(() => _medications.remove(medication)),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Authorization',
              icon: Icons.draw_outlined,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 620;
                  final signature = Column(
                    children: [
                      const Text('Signature'),
                      const SizedBox(height: 8),
                      SignaturePad(
                        onSigned: (data) => setState(() => _signature = data),
                      ),
                    ],
                  );
                  final stamp = Column(
                    children: [
                      const Text('Professional stamp'),
                      const SizedBox(height: 8),
                      CachetMedecin(
                        imageBytes: _stamp,
                        onSelect: (bytes) => setState(() => _stamp = bytes),
                      ),
                    ],
                  );

                  return wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: signature),
                            const SizedBox(width: 18),
                            Expanded(child: stamp),
                          ],
                        )
                      : Column(
                          children: [
                            signature,
                            const SizedBox(height: 18),
                            stamp,
                          ],
                        );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_rounded),
          label: Text(
            _saving ? 'Creating prescription…' : 'Create prescription',
          ),
        ),
      ),
    );
  }
}

class _MedicationEditorDialog extends StatefulWidget {
  const _MedicationEditorDialog({required this.medication});

  final Medicament medication;

  @override
  State<_MedicationEditorDialog> createState() =>
      _MedicationEditorDialogState();
}

class _MedicationEditorDialogState extends State<_MedicationEditorDialog> {
  late final TextEditingController _dosage;
  late final TextEditingController _frequency;

  @override
  void initState() {
    super.initState();
    _dosage = TextEditingController(text: widget.medication.dosage ?? '');
    _frequency = TextEditingController(text: widget.medication.posologie ?? '');
  }

  @override
  void dispose() {
    _dosage.dispose();
    _frequency.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.medication.name),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if ((widget.medication.usage ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(widget.medication.usage!),
              ),
            TextField(
              controller: _dosage,
              decoration: const InputDecoration(labelText: 'Dosage / strength'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _frequency,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Frequency and instructions',
                alignLabelWithHint: true,
              ),
            ),
            if ((widget.medication.warning ?? '').isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                widget.medication.warning!,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(
              context,
              Medicament(
                name: widget.medication.name,
                usage: widget.medication.usage,
                dosage: _dosage.text.trim(),
                posologie: _frequency.text.trim(),
                laboratoire: widget.medication.laboratoire,
                route: widget.medication.route,
                warning: widget.medication.warning,
              ),
            );
          },
          child: const Text('Add medication'),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primary),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
