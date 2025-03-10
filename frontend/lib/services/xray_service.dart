import 'base_service.dart';
import 'api_service.dart';

class XrayService extends BaseService {
  XrayService(ApiService api) : super(api, 'xray');

  Future<dynamic> analyzeImage(String imageId, Map<String, dynamic> analysisParams) async {
    return _api.post('api/xray/$imageId/analyze', analysisParams);
  }

  Future<dynamic> getAnalysisResults(String imageId) async {
    return getById(imageId);
  }

  Future<dynamic> getPendingAnalyses() async {
    return getAll({'status': 'pending'});
  }

  Future<dynamic> updateAnalysisStatus(String imageId, String status) async {
    return update(imageId, {'status': status});
  }
}
