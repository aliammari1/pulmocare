import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/appointment.dart';
import '../services/appointment_service.dart';
import '../services/auth_view_model.dart';
import '../theme/app_theme.dart';
import '../widgets/appointment_booking_dialog.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final AppointmentService _service = AppointmentService();
  List<Appointment> _appointments = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = context.read<AuthViewModel>();
    try {
      final role = auth.userRole;
      final userId = auth.userId;
      final appointments = await _service.listAppointments(
        patientId: role == 'patient' ? userId : null,
        providerId:
            role == 'doctor' || role == 'radiologist' ? userId : null,
      );

      if (!mounted) return;
      setState(() {
        _appointments = appointments;
        _loading = false;
      });
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(error);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load appointments.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();
    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBar(title: const Text('Appointments')),
      body: body,
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _StateMessage(
        icon: Icons.cloud_off_outlined,
        title: 'Appointments unavailable',
        message: _error!,
        actionLabel: 'Retry',
        onAction: _load,
      );
    }

    if (_appointments.isEmpty) {
      final auth = context.read<AuthViewModel>();
      final canBook = auth.userRole == 'patient' &&
          auth.userId != null &&
          auth.userId!.isNotEmpty;
      return _StateMessage(
        icon: Icons.event_available_outlined,
        title: 'No appointments scheduled',
        message: canBook
            ? 'Choose a clinical provider and request your first appointment.'
            : 'Appointments returned by the scheduling service will appear here.',
        actionLabel: canBook ? 'Book appointment' : 'Refresh',
        onAction: canBook ? _bookAppointment : _load,
      );
    }

    final now = DateTime.now();
    final upcoming =
        _appointments.where((item) => item.appointmentDate.isAfter(now)).toList();
    final previous =
        _appointments.where((item) => !item.appointmentDate.isAfter(now)).toList()
          ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (context.read<AuthViewModel>().userRole == 'patient') ...[
            FilledButton.icon(
              onPressed: _bookAppointment,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Book appointment'),
            ),
            const SizedBox(height: 20),
          ],
          if (upcoming.isNotEmpty) ...[
            Text('Upcoming', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            for (final appointment in upcoming)
              _AppointmentCard(
                appointment: appointment,
                onCancel: _canCancel(appointment)
                    ? () => _cancel(appointment)
                    : null,
              ),
          ],
          if (previous.isNotEmpty) ...[
            if (upcoming.isNotEmpty) const SizedBox(height: 24),
            Text('Previous', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            for (final appointment in previous)
              _AppointmentCard(appointment: appointment),
          ],
        ],
      ),
    );
  }

  Future<void> _bookAppointment() async {
    final auth = context.read<AuthViewModel>();
    final patientId = auth.userId;
    if (patientId == null || patientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your session is missing a patient ID.')),
      );
      return;
    }

    final booked = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AppointmentBookingDialog(patientId: patientId),
    );
    if (!mounted || booked != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Appointment request submitted.')),
    );
    await _load();
  }

  bool _canCancel(Appointment appointment) =>
      appointment.status == 'pending' ||
      appointment.status == 'accepted' ||
      appointment.status == 'scheduled' ||
      appointment.status == 'confirmed';

  Future<void> _cancel(Appointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel appointment?'),
        content: Text(
          'Cancel the appointment on '
          '${DateFormat.yMMMd().add_jm().format(appointment.appointmentDate.toLocal())}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel appointment'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.cancelAppointment(appointment.id);
      await _load();
    } on DioException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(error))),
      );
    }
  }

  String _friendlyError(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['detail'] is String) {
      return data['detail'] as String;
    }
    if (error.response?.statusCode == 401) {
      return 'Your session is no longer valid. Sign in again.';
    }
    return 'Unable to reach the appointments service.';
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    this.onCancel,
  });

  final Appointment appointment;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthViewModel>();
    final isPatient = auth.userRole == 'patient';
    final counterparty = isPatient
        ? 'Provider ${_shortId(appointment.providerId)}'
        : 'Patient ${_shortId(appointment.patientId)}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        counterparty,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat.yMMMd()
                            .add_jm()
                            .format(appointment.appointmentDate.toLocal()),
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: appointment.status),
              ],
            ),
            if (appointment.reason != null) ...[
              const SizedBox(height: 14),
              Text(appointment.reason!),
            ],
            const SizedBox(height: 10),
            Text(
              '${appointment.appointmentType} • '
              '${appointment.durationMinutes} min'
              '${appointment.virtual ? ' • Virtual' : ''}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (onCancel != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Cancel'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _shortId(String value) {
    if (value.isEmpty) return 'unknown';
    return value.length <= 8 ? value : value.substring(0, 8);
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(status.replaceAll('_', ' ')),
    );
  }
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
        child: Column(
          children: [
            Icon(icon, size: 56, color: AppTheme.primary),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
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
    );
  }
}
