import 'package:dio/dio.dart';
import 'package:medapp/config.dart';

class DoctorService {
  final Dio _dio = Dio(BaseOptions(baseUrl: Config.apiBaseUrl));

  /// 📌 **Méthode pour récupérer tous les docteurs**
  Future<List<Map<String, dynamic>>> getDoctors() async {
    try {
      final response = await _dio.get('/doctors');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      print("❌ Erreur lors de la récupération des docteurs : $e");
      throw 'Impossible de récupérer les docteurs';
    }
  }

  /// 📌 **Méthode pour récupérer le profil d'un docteur**
  Future<Map<String, dynamic>> getDoctorProfile(String doctorId) async {
    try {
      final response = await _dio.get(
        '/profile',
        queryParameters: {'id': doctorId},
      );
      return response.data;
    } catch (e) {
      print("❌ Erreur lors de la récupération du profil du docteur : $e");
      throw 'Impossible de récupérer le profil du docteur';
    }
  }
}
