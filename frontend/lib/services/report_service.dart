import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'base_service.dart';
import 'api_service.dart';

class ReportService extends BaseService {
  ReportService(ApiService api) : super(api, 'reports');

  Future<dynamic> createReport(Map<String, dynamic> reportData) async {
    return create(reportData);
  }

  Future<dynamic> getPatientReports(String patientId) async {
    return getAll({'patient_id': patientId});
  }

  Future<dynamic> updateReportStatus(String reportId, String status) async {
    return update(reportId, {'status': status});
  }

  Future<dynamic> searchReports(Map<String, dynamic> searchParams) async {
    return getAll(searchParams);
  }

  Future<dynamic> analyzeReport(String reportId, Map<String, dynamic> analysisParams) async {
    return _api.post('api/reports/$reportId/analyze', analysisParams);
  }

  Future<dynamic> exportReport(String reportId, String format) async {
    return _api.get('api/reports/$reportId/export', headers: {
      'Accept': format == 'pdf' ? 'application/pdf' : 'application/json'
    });
  }

  Future<dynamic> getReportsByPatient(String patientId) async {
    return getAll({'patient_id': patientId});
  }

  Future<dynamic> getReportsByDoctor(String doctorId) async {
    return getAll({'doctor_id': doctorId});
  }

  final http.Client _client = http.Client();

  Future<void> deleteReport(String id) async {
    try {
      final response = await _client.delete(
        Uri.parse('${ApiConfig.gatewayUrl}/reports/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to delete report: ${json.decode(response.body)['error']}');
      }
    } catch (e) {
      throw Exception('Error deleting report: $e');
    }
  }
}
