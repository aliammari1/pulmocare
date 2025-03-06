import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/xray_service.dart';
import '../services/service_locator.dart';

enum AnalysisStatus { idle, loading, success, error }

class XRayProvider with ChangeNotifier {
  final XRayService _xrayService = locator<XRayService>();
  AnalysisStatus _status = AnalysisStatus.idle;
  String? _error;
  Map<String, dynamic>? _currentAnalysis;
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = false;

  AnalysisStatus get status => _status;
  String? get error => _error;
  Map<String, dynamic>? get currentAnalysis => _currentAnalysis;
  List<Map<String, dynamic>> get history => _history;
  bool get isLoading => _isLoading;

  Future<void> analyzeXRay(Uint8List imageBytes, String filename,
      {Map<String, dynamic>? metadata}) async {
    try {
      _status = AnalysisStatus.loading;
      _error = null;
      notifyListeners();

      final result =
          await _xrayService.analyzeXRay(imageBytes, filename, metadata);
      _currentAnalysis = result;
      _status = AnalysisStatus.success;
    } catch (e) {
      _error = e.toString();
      _status = AnalysisStatus.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadHistory(String patientId) async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      notifyListeners();

      _history = await _xrayService.getHistory(patientId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearCurrentAnalysis() {
    _currentAnalysis = null;
    _status = AnalysisStatus.idle;
    _error = null;
    notifyListeners();
  }

  void clearAnalysis() {
    _currentAnalysis = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  void reset() {
    _currentAnalysis = null;
    clearAnalysis();
  }
}
