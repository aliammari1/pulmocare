import 'package:dio/dio.dart';

import '../models/appointment.dart';
import '../models/clinical_provider.dart';
import '../utils/dio_client.dart';

class AppointmentService {
  AppointmentService({Dio? dio}) : _dio = dio ?? DioHttpClient().dio;

  final Dio _dio;

  Future<List<Appointment>> listAppointments({
    String? patientId,
    String? providerId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final now = DateTime.now().toUtc();
    final from = (startDate ?? now.subtract(const Duration(days: 180))).toUtc();
    final to = (endDate ?? now.add(const Duration(days: 365))).toUtc();

    final response = await _dio.get<Map<String, dynamic>>(
      'appointments',
      queryParameters: {
        if (patientId != null && patientId.isNotEmpty) 'patient_id': patientId,
        if (providerId != null && providerId.isNotEmpty)
          'provider_id': providerId,
        'start_date': from.toIso8601String(),
        'end_date': to.toIso8601String(),
        'limit': 100,
      },
    );

    final data = response.data ?? const {};
    final items = data['items'];
    if (items is! List) return const [];

    return items
        .whereType<Map>()
        .map(
          (item) => Appointment.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .where((item) => item.id.isNotEmpty)
        .toList()
      ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
  }

  Future<Appointment> createAppointment({
    required String patientId,
    required ClinicalProvider provider,
    required DateTime appointmentDate,
    required String appointmentType,
    required String reason,
    int durationMinutes = 30,
    bool virtual = false,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'appointments/',
      data: {
        'patient_id': patientId,
        'provider_id': provider.id,
        'provider_type': provider.providerType,
        'appointment_type': appointmentType,
        'appointment_date': appointmentDate.toUtc().toIso8601String(),
        'duration_minutes': durationMinutes,
        'reason': reason.trim().isEmpty ? null : reason.trim(),
        'virtual': virtual,
      },
    );

    return Appointment.fromJson(response.data ?? const {});
  }

  Future<void> cancelAppointment(String appointmentId) async {
    await _dio.delete<void>('appointments/$appointmentId');
  }
}
