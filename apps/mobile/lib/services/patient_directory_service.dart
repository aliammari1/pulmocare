import 'package:dio/dio.dart';

import '../models/patient_directory_entry.dart';
import '../utils/DioClient.dart';

class PatientDirectoryService {
  PatientDirectoryService({Dio? dio}) : _dio = dio ?? DioHttpClient().dio;

  final Dio _dio;

  Future<List<PatientDirectoryEntry>> listPatients() async {
    final response = await _dio.get<List<dynamic>>(
      'auth/users',
      queryParameters: const {
        'role': 'patient',
        'first': 0,
        'max': 100,
      },
    );

    return (response.data ?? const [])
        .whereType<Map>()
        .map(
          (item) => PatientDirectoryEntry.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .where((patient) => patient.id.isNotEmpty)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }
}
