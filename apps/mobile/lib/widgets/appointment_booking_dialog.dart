import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/clinical_provider.dart';
import '../services/appointment_service.dart';
import '../services/provider_directory_service.dart';

class AppointmentBookingDialog extends StatefulWidget {
  const AppointmentBookingDialog({
    super.key,
    required this.patientId,
  });

  final String patientId;

  @override
  State<AppointmentBookingDialog> createState() =>
      _AppointmentBookingDialogState();
}

class _AppointmentBookingDialogState extends State<AppointmentBookingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  final _directory = ProviderDirectoryService();
  final _appointments = AppointmentService();

  List<ClinicalProvider> _providers = const [];
  ClinicalProvider? _provider;
  DateTime? _dateTime;
  String _appointmentType = 'consultation';
  bool _virtual = false;
  bool _loadingProviders = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _loadProviders() async {
    try {
      final providers = await _directory.listProviders();
      if (!mounted) return;
      setState(() {
        _providers = providers;
        _provider = providers.isEmpty ? null : providers.first;
        _loadingProviders = false;
      });
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingProviders = false;
        _error = _message(error, 'Unable to load clinical providers.');
      });
    }
  }

  Future<void> _chooseDateTime() async {
    final now = DateTime.now();
    final initial = _dateTime ?? now.add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1, now.month, now.day),
      initialDate: initial,
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;

    final selected = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (!selected.isAfter(DateTime.now())) {
      setState(() => _error = 'Choose a future date and time.');
      return;
    }

    setState(() {
      _dateTime = selected;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = _provider;
    final dateTime = _dateTime;
    if (provider == null) {
      setState(() => _error = 'Choose a clinical provider.');
      return;
    }
    if (dateTime == null) {
      setState(() => _error = 'Choose an appointment date and time.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await _appointments.createAppointment(
        patientId: widget.patientId,
        provider: provider,
        appointmentDate: dateTime,
        appointmentType: _appointmentType,
        reason: _reason.text,
        virtual: _virtual,
      );
      if (mounted) Navigator.pop(context, true);
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = _message(error, 'Unable to book this appointment.');
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Unable to book this appointment.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Book appointment'),
      content: SizedBox(
        width: 560,
        child: _loadingProviders
            ? const Padding(
                padding: EdgeInsets.all(36),
                child: Center(child: CircularProgressIndicator()),
              )
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_providers.isEmpty)
                        const Text(
                          'No clinical providers are currently available in the directory.',
                        )
                      else
                        DropdownButtonFormField<ClinicalProvider>(
                          initialValue: _provider,
                          decoration: const InputDecoration(
                            labelText: 'Clinical provider',
                            prefixIcon: Icon(Icons.medical_services_outlined),
                          ),
                          items: [
                            for (final provider in _providers)
                              DropdownMenuItem(
                                value: provider,
                                child: Text(
                                  provider.specialty == null
                                      ? provider.name
                                      : '${provider.name} • ${provider.specialty}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: _saving
                              ? null
                              : (value) => setState(() => _provider = value),
                        ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _appointmentType,
                        decoration: const InputDecoration(
                          labelText: 'Appointment type',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'consultation',
                            child: Text('Consultation'),
                          ),
                          DropdownMenuItem(
                            value: 'initial',
                            child: Text('Initial consultation'),
                          ),
                          DropdownMenuItem(
                            value: 'followUp',
                            child: Text('Follow-up'),
                          ),
                        ],
                        onChanged: _saving
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() => _appointmentType = value);
                                }
                              },
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: _saving ? null : _chooseDateTime,
                        icon: const Icon(Icons.event_outlined),
                        label: Text(
                          _dateTime == null
                              ? 'Choose date and time'
                              : DateFormat.yMMMd()
                                  .add_jm()
                                  .format(_dateTime!),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _reason,
                        minLines: 2,
                        maxLines: 4,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          labelText: 'Reason for visit',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.notes_outlined),
                        ),
                        validator: (value) =>
                            (value?.trim().length ?? 0) < 3
                                ? 'Briefly describe the reason for the visit.'
                                : null,
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _virtual,
                        onChanged:
                            _saving ? null : (value) => setState(() => _virtual = value),
                        title: const Text('Virtual appointment'),
                        subtitle: const Text(
                          'The provider can add meeting details after confirmation.',
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _error!,
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
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving || _providers.isEmpty ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Request appointment'),
        ),
      ],
    );
  }

  static String _message(DioException error, String fallback) {
    final data = error.response?.data;
    if (data is Map && data['detail'] is String) {
      return data['detail'] as String;
    }
    return fallback;
  }
}
