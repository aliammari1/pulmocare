import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../models/medicament.dart';
import '../models/ordonnance.dart';
import '../utils/DioClient.dart';

class ApiService {
  ApiService({Dio? dio})
    : dio = dio ?? DioHttpClient().dio,
      _openFda = Dio(
        BaseOptions(
          baseUrl: 'https://api.fda.gov/drug/',
          connectTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 20),
          headers: const {'Accept': 'application/json'},
        ),
      );

  static const String _openFdaApiKey = String.fromEnvironment(
    'OPENFDA_API_KEY',
  );

  final Dio dio;
  final Dio _openFda;

  Future<List<Medicament>> searchMedicaments(String query) async {
    final value = query.trim();
    if (value.length < 2) return const [];

    try {
      final response = await _openFda.get<Map<String, dynamic>>(
        'label.json',
        queryParameters: {
          'search':
              'openfda.brand_name:"$value" OR openfda.generic_name:"$value"',
          'limit': 20,
          if (_openFdaApiKey.isNotEmpty) 'api_key': _openFdaApiKey,
        },
      );
      final results = response.data?['results'];
      if (results is! List) return const [];

      return results
          .whereType<Map>()
          .map((item) {
            final data = item.map(
              (key, value) => MapEntry(key.toString(), value),
            );
            final openFda = data['openfda'] is Map
                ? (data['openfda'] as Map).map(
                    (key, value) => MapEntry(key.toString(), value),
                  )
                : const <String, dynamic>{};

            String first(dynamic value) {
              if (value is List && value.isNotEmpty) {
                return value.first?.toString() ?? '';
              }
              return value?.toString() ?? '';
            }

            String joined(dynamic value) {
              if (value is! List) return '';
              return value
                  .map((entry) => entry.toString().trim())
                  .where((entry) => entry.isNotEmpty)
                  .join('\n');
            }

            final brand = first(openFda['brand_name']);
            final generic = first(openFda['generic_name']);
            final dosageForm = first(openFda['dosage_form']);
            final strength = first(openFda['strength']);
            final dosage = [
              dosageForm,
              strength,
            ].where((entry) => entry.isNotEmpty).join(' ');

            final administration = joined(data['dosage_and_administration']);
            final fallbackAdministration = joined(
              data['dosage_forms_and_strengths'],
            );

            return Medicament(
              name: brand.isNotEmpty ? brand : generic,
              usage: generic,
              dosage: dosage,
              posologie: administration.isNotEmpty
                  ? administration
                  : fallbackAdministration,
              laboratoire: first(openFda['manufacturer_name']),
              route: first(openFda['route']),
              warning: joined(data['warnings']),
            );
          })
          .where((medication) => medication.name.isNotEmpty)
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    } on DioException {
      return const [];
    }
  }

  Future<Map<String, dynamic>> createOrdonnance(Ordonnance ordonnance) async {
    final response = await dio.post<Map<String, dynamic>>(
      'ordonnances',
      data: ordonnance.toJson(),
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('Prescription API returned no data');
    }
    return data;
  }

  Future<List<Ordonnance>> getDoctorOrdonnances(String doctorId) async {
    final response = await dio.get<Map<String, dynamic>>(
      'ordonnances',
      queryParameters: {'doctor_id': doctorId, 'limit': 100},
    );
    final items = response.data?['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map(
          (item) => Ordonnance.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> getMedecinOrdonnances(
    String doctorId,
  ) async {
    final response = await dio.get<Map<String, dynamic>>(
      'ordonnances',
      queryParameters: {'doctor_id': doctorId, 'limit': 100},
    );
    final items = response.data?['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map(
          (item) => item.map((key, value) => MapEntry(key.toString(), value)),
        )
        .toList();
  }

  Future<Map<String, dynamic>?> getMedecinOrdonnance(String ordonnanceId) =>
      getSingleOrdonnance(ordonnanceId);

  Future<Map<String, dynamic>?> getSingleOrdonnance(String ordonnanceId) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        'ordonnances/$ordonnanceId',
      );
      return response.data;
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<Uint8List?> getOrdonnancePdf(String ordonnanceId) async {
    try {
      final response = await dio.get<List<int>>(
        'generate-pdf/$ordonnanceId',
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      return bytes == null ? null : Uint8List.fromList(bytes);
    } on DioException {
      return null;
    }
  }

  Future<String> saveOrdonnancePdf(
    String ordonnanceId,
    Uint8List pdfBytes,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/prescription_$ordonnanceId.pdf');
    await file.writeAsBytes(pdfBytes, flush: true);
    return file.path;
  }

  Future<String> savePdf(
    String doctorId,
    String ordonnanceId,
    Uint8List pdfBytes,
  ) {
    return saveOrdonnancePdf(ordonnanceId, pdfBytes);
  }

  Future<List<Map<String, dynamic>>> getMedecinPdfs(String doctorId) async {
    final prescriptions = await getMedecinOrdonnances(doctorId);
    return prescriptions
        .map(
          (item) => {
            'ordonnance_id': (item['id'] ?? item['_id'] ?? '').toString(),
            'patient_id': (item['patient_id'] ?? '').toString(),
            'date': item['date'],
            'available': true,
          },
        )
        .toList();
  }

  Future<Uint8List> downloadPdf(String filename) async {
    final match = RegExp(r'prescription_(.+)\.pdf$').firstMatch(filename);
    if (match == null) {
      throw ArgumentError('Invalid prescription PDF filename');
    }
    final bytes = await getOrdonnancePdf(match.group(1)!);
    if (bytes == null) {
      throw StateError('Prescription PDF is unavailable');
    }
    return bytes;
  }

  Future<Uint8List?> generatePdfFromData(
    Map<String, dynamic> ordonnance,
  ) async {
    try {
      return await Ordonnance.fromJson(ordonnance).generatePdf();
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, String>> getPatientEmail(String patientId) async {
    final response = await dio.get<Map<String, dynamic>>(
      'auth/patients/$patientId/contact',
    );
    final data = response.data ?? const <String, dynamic>{};
    return {
      'email': data['email']?.toString() ?? '',
      'name': data['name']?.toString() ?? '',
    };
  }
}
