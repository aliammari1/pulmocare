import 'package:dio/dio.dart';

import '../models/report.dart';
import '../utils/DioClient.dart';

class ApiService {
  ApiService({Dio? dio}) : _dio = dio ?? DioHttpClient().dio;

  final Dio _dio;

  Future<List<Report>> getReports({String? search}) async {
    final response = await _dio.get<List<dynamic>>(
      'reports/',
      queryParameters: {
        if (search != null && search.trim().isNotEmpty)
          'search': search.trim(),
      },
    );

    return (response.data ?? const [])
        .whereType<Map>()
        .map(
          (item) => Report.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<Report> getReportById(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('reports/$id');
    return Report.fromJson(response.data ?? const {});
  }

  Future<Report> createReport(Map<String, dynamic> data) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'reports/',
      data: data,
    );
    return Report.fromJson(response.data ?? const {});
  }

  Future<Report> updateReport(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.put<Map<String, dynamic>>(
      'reports/$id',
      data: data,
    );
    return Report.fromJson(response.data ?? const {});
  }

  Future<void> deleteReport(String id) async {
    await _dio.delete<void>('reports/$id');
  }
}
