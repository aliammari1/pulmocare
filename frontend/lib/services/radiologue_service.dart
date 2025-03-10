import 'base_service.dart';
import 'api_service.dart';

class RadiologueService extends BaseService {
  RadiologueService(ApiService api) : super(api, 'radiologue');

  Future<dynamic> getPendingAnalyses() async {
    return getAll({'status': 'pending'});
  }

  Future<dynamic> submitAnalysisResult(
      String analysisId, Map<String, dynamic> result) async {
    return update(analysisId, {'result': result, 'status': 'completed'});
  }

  Future<dynamic> getWorkload(String radiologistId) async {
    return getAll({'radiologist_id': radiologistId, 'type': 'workload'});
  }

  Future<dynamic> assignAnalysis(
      String analysisId, String radiologistId) async {
    return update(
        analysisId, {'radiologist_id': radiologistId, 'status': 'assigned'});
  }

  Future<dynamic> getAnalysisPriority(String analysisId) async {
    return getAll({'analysis_id': analysisId, 'type': 'priority'});
  }
}
