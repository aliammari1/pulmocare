import 'package:dio/dio.dart';
import 'package:medapp/config.dart';

class RapportService {
  final Dio _dio = Dio(BaseOptions(baseUrl: Config.apiBaseUrl));

  /// 📌 **Méthode pour ajouter un rapport**
  Future<void> ajouterRapport({
    required String patientName,
    required String examType,
    required String reportType,
    required String content,
  }) async {
    try {
      await _dio.post(
        '/rapport',
        data: {
          "patientName": patientName,
          "examType": examType,
          "reportType": reportType,
          "content": content,
        },
      );
    } catch (_) {
      throw 'Impossible d\'ajouter le rapport';
    }
  }

  /// 📌 **Méthode pour récupérer tous les rapports**
  Future<List<Map<String, dynamic>>> getRapports() async {
    try {
      final response = await _dio.get('/rapports');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (_) {
      throw 'Impossible de récupérer les rapports';
    }
  }
}
