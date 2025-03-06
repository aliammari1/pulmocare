import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/knowledge_service.dart';
import '../services/service_locator.dart';
import '../services/cache_service.dart';
import '../services/api_config.dart';

class ReportProvider with ChangeNotifier {
  final KnowledgeService _knowledgeService = locator<KnowledgeService>();
  final CacheService _cacheService = locator<CacheService>();
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get reports => _reports;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadReports() async {
    // This calls searchReports with an empty query to load all reports
    return searchReports('');
  }

  Future<void> searchReports(String query) async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Try to get from cache first
      final cacheKey = 'search_$query';
      if (_cacheService.hasValidCache(cacheKey)) {
        final cachedResults = await _cacheService.get<List<dynamic>>(cacheKey);
        if (cachedResults != null) {
          _reports = cachedResults.cast<Map<String, dynamic>>();
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      // If not in cache, fetch from service
      final results = await _knowledgeService.searchKnowledge(query);
      _reports = results;

      // Cache the results
      await _cacheService.set(cacheKey, results);
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

      final entities = await _knowledgeService.extractEntities(text);
      final suggestions = await _knowledgeService.getRecommendations(text);

      return {
        'entities': entities,
        'suggestions': suggestions,
      };
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

      await _knowledgeService.deleteReport(id);
      _reports.removeWhere((report) => report['id'] == id);
    } catch (e) {
      _error = e.toString();
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

      return await _knowledgeService.exportReport(id, format: format);
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createReport(Map<String, dynamic> report) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/reports'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(report),
      );

      if (response.statusCode != 201) {
        throw Exception(
            'Failed to create report: ${jsonDecode(response.body)['error']}');
      }

      final newReport = jsonDecode(response.body);
      _reports.add(newReport);
      await _cacheService.invalidate('search_'); // Invalidate search cache
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateReport(Map<String, dynamic> report) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (report['id'] == null) {
        throw Exception('Report ID is required for update');
      }

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/reports/${report['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(report),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to update report: ${jsonDecode(response.body)['error']}');
      }

      final updatedReport = jsonDecode(response.body);
      final index = _reports.indexWhere((r) => r['id'] == report['id']);
      if (index != -1) {
        _reports[index] = updatedReport;
      }
      await _cacheService.invalidate('search_'); // Invalidate search cache
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
}
