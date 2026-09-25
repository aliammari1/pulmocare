import 'package:dio/dio.dart';

import '../models/appointment.dart';
import '../utils/DioClient.dart';

class AppointmentService {
  AppointmentService({Dio? dio}) : _dio = dio ?? DioHttpClient().dio;

  final Dio _dio;

  Future<List<Appointment>> listAppointments({
    String? patientId,
    String? providerId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      'appointments',
      queryParameters: {
        if (patientId != null && patientId.isNotEmpty) 'patient_id': patientId,
        if (providerId != null && providerId.isNotEmpty)
          'provider_id': providerId,
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
        .toList()
      ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
  }

  Future<void> cancelAppointment(String appointmentId) async {
    await _dio.delete<void>('appointments/$appointmentId');
  }
}
