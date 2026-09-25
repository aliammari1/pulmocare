import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/patient_directory_entry.dart';
import '../services/patient_directory_service.dart';
import '../theme/app_theme.dart';

class PatientPickerDialog extends StatefulWidget {
  const PatientPickerDialog({super.key});

  @override
  State<PatientPickerDialog> createState() => _PatientPickerDialogState();
}

class _PatientPickerDialogState extends State<PatientPickerDialog> {
  final _service = PatientDirectoryService();
  final _search = TextEditingController();

  List<PatientDirectoryEntry> _patients = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final patients = await _service.listPatients();
      if (!mounted) return;
      setState(() {
        _patients = patients;
        _loading = false;
        _error = null;
      });
    } on DioException catch (error) {
      if (!mounted) return;
      final data = error.response?.data;
      setState(() {
        _loading = false;
        _error = data is Map && data['detail'] is String
            ? data['detail'] as String
            : 'Unable to load the patient directory.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final visible = query.isEmpty
        ? _patients
        : _patients
            .where(
              (patient) =>
                  patient.name.toLowerCase().contains(query) ||
                  patient.email.toLowerCase().contains(query),
            )
            .toList();

    return AlertDialog(
      title: const Text('Select patient'),
      content: SizedBox(
        width: 620,
        height: 520,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 14),
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _loading = true;
                              _error = null;
                            });
                            _load();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      TextField(
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'Search by name or email',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: visible.isEmpty
                            ? const Center(
                                child: Text('No matching patients.'),
                              )
                            : ListView.separated(
                                itemCount: visible.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (_, index) {
                                  final patient = visible[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: AppTheme.primary
                                          .withValues(alpha: .10),
                                      child: Text(
                                        patient.initials,
                                        style: const TextStyle(
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    title: Text(patient.name),
                                    subtitle: Text(patient.email),
                                    trailing:
                                        const Icon(Icons.chevron_right_rounded),
                                    onTap: () =>
                                        Navigator.pop(context, patient),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
