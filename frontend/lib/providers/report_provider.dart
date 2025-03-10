import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/medical_report.dart';
import '../services/cache_service.dart';
import '../services/api_config.dart';

class ReportProvider with ChangeNotifier {
  final CacheService _cacheService;
  List<MedicalReport> _reports = [];
  String? _error;
  bool _isLoading = false;
  bool _isMongoDBConnected = true;

  ReportProvider(this._cacheService);

  List<MedicalReport> get reports => _reports;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isMongoDBConnected => _isMongoDBConnected;

  Future<void> loadReports() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await http.get(
        Uri.parse('${ApiConfig.gatewayUrl}/api/reports'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _cacheService.get('token')}',
        },
      );

      if (response.statusCode == 200) {
        _reports = List<Map<String, dynamic>>.from(jsonDecode(response.body))
            .map((json) => MedicalReport.fromJson(json))
            .toList();
        await _cacheService.set('reports', response.body);
        _isMongoDBConnected = true;
      } else {
        throw Exception('Failed to load reports: ${response.body}');
      }
    } catch (e) {
      _handleError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchReports(String query) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Check cache for recent searches
      final cacheKey = 'search_$query';
      final cachedData = await _cacheService.get(cacheKey);
      if (cachedData != null) {
        _reports = List<Map<String, dynamic>>.from(jsonDecode(cachedData))
            .map((json) => MedicalReport.fromJson(json))
            .toList();
        notifyListeners();
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.reportSearchUrl}?q=$query'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        _reports = List<Map<String, dynamic>>.from(jsonDecode(response.body))
            .map((json) => MedicalReport.fromJson(json))
            .toList();
        await _cacheService.set(cacheKey, response.body,
            expiry: const Duration(minutes: 5));
      } else {
        throw Exception('Failed to search reports: ${response.body}');
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> analyzeReport(String text) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await http.post(
        Uri.parse(ApiConfig.reportAnalyzeUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'content': text}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to analyze report: ${response.body}');
      }

      return jsonDecode(response.body);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createReport(MedicalReport report) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await http.post(
        Uri.parse(ApiConfig.reportsUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(report.toJson()),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to create report: ${response.body}');
      }

      final newReport = MedicalReport.fromJson(jsonDecode(response.body));
      _reports.add(newReport);
      await _cacheService.invalidate('reports');
      await _cacheService.invalidate('search_');
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateReport(MedicalReport report) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await http.put(
        Uri.parse(ApiConfig.reportUrl(report.id)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(report.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update report: ${response.body}');
      }

      final updatedReport = MedicalReport.fromJson(jsonDecode(response.body));
      final index = _reports.indexWhere((r) => r.id == report.id);
      if (index != -1) {
        _reports[index] = updatedReport;
      }
      await _cacheService.invalidate('reports');
      await _cacheService.invalidate('search_');
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteReport(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await http.delete(
        Uri.parse(ApiConfig.reportUrl(id)),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 204) {
        throw Exception('Failed to delete report: ${response.body}');
      }

      _reports.removeWhere((report) => report.id == id);
      await _cacheService.invalidate('reports');
      await _cacheService.invalidate('search_');
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Uint8List?> exportReport(String id, {String format = 'pdf'}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await http.get(
        Uri.parse('${ApiConfig.reportExportUrl(id)}?format=$format'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': format == 'pdf' ? 'application/pdf' : 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to export report: ${response.body}');
      }

      return response.bodyBytes;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addAnnotation(String reportId, Annotation annotation) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await http.post(
        Uri.parse('${ApiConfig.reportUrl(reportId)}/annotations'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(annotation.toJson()),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to add annotation: ${response.body}');
      }

      // Update local report
      final index = _reports.indexWhere((r) => r.id == reportId);
      if (index != -1) {
        final report = _reports[index];
        _reports[index] = MedicalReport(
          id: report.id,
          title: report.title,
          content: report.content,
          createdAt: report.createdAt,
          updatedAt: DateTime.now(),
          annotations: [...report.annotations, annotation],
        );
      }

      await _cacheService.invalidate('reports');
      await _cacheService.invalidate('search_');
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAnnotation(String reportId, int index) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await http.delete(
        Uri.parse('${ApiConfig.reportUrl(reportId)}/annotations/$index'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 204) {
        throw Exception('Failed to delete annotation: ${response.body}');
      }

      // Update local report
      final reportIndex = _reports.indexWhere((r) => r.id == reportId);
      if (reportIndex != -1) {
        final report = _reports[reportIndex];
        final annotations = List<Annotation>.from(report.annotations);
        annotations.removeAt(index);

        _reports[reportIndex] = MedicalReport(
          id: report.id,
          title: report.title,
          content: report.content,
          createdAt: report.createdAt,
          updatedAt: DateTime.now(),
          annotations: annotations,
        );
      }

      await _cacheService.invalidate('reports');
      await _cacheService.invalidate('search_');
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> clearCache() async {
    await _cacheService.invalidateAll();
    notifyListeners();
  }

  // Add analytics methods
  Map<DateTime, int> getReportTrends() {
    final trends = <DateTime, int>{};
    for (var report in _reports) {
      final date = DateTime(
        report.createdAt.year,
        report.createdAt.month,
        report.createdAt.day,
      );
      trends[date] = (trends[date] ?? 0) + 1;
    }
    return trends;
  }

  void _handleError(dynamic error) {
    if (error.toString().contains('Connection refused') ||
        error.toString().contains('Connection failed')) {
      _error = 'Gateway connection error. Please try again later.';
    } else {
      _error = error.toString();
    }
  }
}
