import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import '../models/medicament.dart';
import '../models/ordonnance.dart';
import '../constants.dart';
import 'package:dio/dio.dart'; // نستخدم Dio بدلاً من http
import 'dart:io' show Platform;

class ApiService {
  static const String openFdaBaseUrl = 'https://api.fda.gov/drug';
  // Mise à jour de la clé API FDA
  static const String apiKey = '4DpshbRmBvQ4k0hg27yZT2zEEFvYVHbqa8WHlhan';
  static const Duration timeoutDuration = Duration(seconds: 10);
  static const int maxRetries = 3;
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://192.168.190.173:5000';
    } else {
      return 'http://192.168.190.173:5000';
    }
  }

  static String get backendBaseUrl => baseUrl;

  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    validateStatus: (status) => true, // للتحقق من جميع حالات الاستجابة
  ));

  Future<List<Medicament>> searchMedicaments(String query) async {
    try {
      print("Searching medications with query: $query");

      // D'abord, chercher dans la base de données locale
      final localResults = await searchLocalMedicaments(query);
      if (localResults.isNotEmpty) {
        return localResults;
      }

      // Si rien trouvé localement, chercher via l'API FDA
      return await searchFdaMedicaments(query);
    } catch (e) {
      print('Erreur recherche médicaments: $e');
      return [];
    }
  }

  Future<List<Medicament>> searchLocalMedicaments(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$backendBaseUrl/medicaments/search?q=$query'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Medicament.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Erreur recherche locale: $e');
      return [];
    }
  }

  Future<List<Medicament>> searchFdaMedicaments(String query) async {
    try {
      if (query.length < 2) return [];

      print("Starting OpenFDA search with query: $query");
      List<Medicament> allResults = [];

      // Construire plusieurs requêtes pour obtenir plus de résultats
      final searchQueries = [
        'openfda.brand_name:$query~', // Recherche approximative du nom de marque
        'openfda.generic_name:$query~', // Recherche approximative du nom générique
        'openfda.substance_name:$query~', // Recherche par substance
        'openfda.manufacturer_name:$query~', // Recherche par fabricant
        '_exists_:openfda.brand_name', // Tous les médicaments avec un nom de marque
      ];

      for (String searchQuery in searchQueries) {
        try {
          final url = Uri.parse('$openFdaBaseUrl/label.json'
              '?api_key=$apiKey'
              '&search=${Uri.encodeComponent(searchQuery)}'
              '&limit=100');

          print("Calling OpenFDA URL for query: $searchQuery");
          final response =
              await http.get(url).timeout(const Duration(seconds: 30));

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data['results'] != null) {
              final results = data['results'] as List;
              print("Found ${results.length} results for query: $searchQuery");

              allResults.addAll(results.map((item) {
                final openfda = item['openfda'] ?? {};
                final name = _getBestName(openfda);
                final dosage =
                    _extractDosageInfo(openfda); // Utiliser la bonne méthode
                final usage = _extractUsageInfo(item);
                final route = _getFirstValue(openfda['route']);

                return Medicament(
                  name: name,
                  dosage: dosage,
                  usage: usage,
                  route: route,
                );
              }).where((med) =>
                  med.name.isNotEmpty && _isMedicamentRelevant(med, query)));
            }
          }
        } catch (e) {
          print('Error in query $searchQuery: $e');
          continue; // Continuer avec la prochaine requête en cas d'erreur
        }
      }

      // Dédupliquer et trier les résultats
      return _getUniqueMedicaments(allResults);
    } catch (e) {
      print('Error in FDA search: $e');
      return [];
    }
  }

  String _getBestName(Map<String, dynamic> openfda) {
    final brandName = _getFirstValue(openfda['brand_name']);
    final genericName = _getFirstValue(openfda['generic_name']);
    final substanceName = _getFirstValue(openfda['substance_name']);

    return brandName ?? genericName ?? substanceName ?? '';
  }

  bool _isMedicamentRelevant(Medicament med, String query) {
    final searchTerms = query.toLowerCase().split(' ');
    final medicamentName = med.name.toLowerCase();

    // Vérifier si au moins un terme de recherche est présent dans le nom
    return searchTerms.any((term) => medicamentName.contains(term));
  }

  String? _getFirstValue(dynamic list) {
    if (list is List && list.isNotEmpty) {
      return list.first.toString();
    }
    return null;
  }

  String _extractUsageInfo(Map<String, dynamic> item) {
    final usageList = item['indications_and_usage'] as List?;
    if (usageList != null && usageList.isNotEmpty) {
      return usageList.first.toString();
    }
    return '';
  }

  String _extractPosologie(Map<String, dynamic> item) {
    final List<String> instructions = [];

    if (item['dosage_and_administration'] is List) {
      instructions.addAll((item['dosage_and_administration'] as List)
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty));
    }

    return instructions.join('\n• ');
  }

  String _extractDosageInstructions(Map<String, dynamic> item) {
    List<String> instructions = [];

    if (item['dosage_and_administration'] != null) {
      instructions.addAll(List<String>.from(item['dosage_and_administration']));
    }
    if (item['dosage_forms_and_strengths'] != null) {
      instructions
          .addAll(List<String>.from(item['dosage_forms_and_strengths']));
    }
    if (item['indications_and_usage'] != null) {
      instructions.addAll(List<String>.from(item['indications_and_usage']));
    }

    return instructions.join('\n');
  }

  String _extractWarningsAndPrecautions(Map<String, dynamic> item) {
    List<String> allWarnings = [];

    if (item['warnings'] != null) {
      allWarnings.addAll(List<String>.from(item['warnings']));
    }
    if (item['warnings_and_cautions'] != null) {
      allWarnings.addAll(List<String>.from(item['warnings_and_cautions']));
    }
    if (item['precautions'] != null) {
      allWarnings.addAll(List<String>.from(item['precautions']));
    }
    if (item['contraindications'] != null) {
      allWarnings.addAll(List<String>.from(item['contraindications']));
    }

    return allWarnings.join('\n• ');
  }

  String _formatPosologie(String instructions) {
    if (instructions.isEmpty) return '';

    // Clean up and format the instructions
    return instructions
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n• ');
  }

  String _extractWarnings(List<dynamic> warnings) {
    return warnings
        .map((w) => w.toString())
        .where((w) => w.isNotEmpty)
        .join('\n• ');
  }

  Future<bool> validateOrdonnance(Ordonnance ordonnance) async {
    final bool hasRequiredIds =
        ordonnance.patientId.isNotEmpty && ordonnance.medecinId.isNotEmpty;
    final bool hasMedicaments = ordonnance.medicaments.isNotEmpty;

    if (!hasRequiredIds) {
      throw Exception('ID patient et ID médecin sont requis');
    }
    if (!hasMedicaments) {
      throw Exception('Au moins un médicament est requis');
    }
    return true;
  }

  Future<Map<String, dynamic>> createOrdonnance(Ordonnance ordonnance) async {
    try {
      print('\n=== ENVOI DE LA REQUÊTE ===');
      final url = Uri.parse('$baseUrl/ordonnances');
      final body = jsonEncode(ordonnance.toJson());

      print('URL: $url');
      print('Body: $body');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      print('\n=== RÉPONSE DU SERVEUR ===');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData is Map<String, dynamic>) {
          return responseData;
        }
        throw Exception('Format de réponse invalide');
      }

      throw Exception('Erreur HTTP ${response.statusCode}: ${response.body}');
    } catch (e) {
      print('\n=== ERREUR DE CRÉATION ===');
      print('Type: ${e.runtimeType}');
      print('Message: $e');
      throw Exception('Erreur lors de la création: $e');
    }
  }

  Future<bool> createOrdonnanceWithRetry(Ordonnance ordonnance) async {
    int retryCount = 0;
    while (retryCount < maxRetries) {
      try {
        final response = await http
            .post(
              Uri.parse('$baseUrl/api/ordonnances'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode(ordonnance.toJson()),
            )
            .timeout(timeoutDuration);

        if (response.statusCode == 201) {
          return true;
        }
        throw Exception('Server error: ${response.statusCode}');
      } catch (e) {
        retryCount++;
        final isConnectionError = e is http.ClientException ||
            e.toString().contains('Connection refused');

        if (isConnectionError) {
          if (retryCount == maxRetries) {
            throw Exception(
                'Unable to connect to server after $maxRetries attempts. '
                'Please check your internet connection and try again.');
          }
          await Future.delayed(Duration(seconds: retryCount));
          continue;
        }
        rethrow;
      }
    }
    return false;
  }

  Future<List<Ordonnance>> getDoctorOrdonnances(String medecinId) async {
    final response = await http.get(
      Uri.parse('$backendBaseUrl/ordonnances/doctor/$medecinId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Ordonnance.fromJson(json)).toList();
    }
    throw Exception('Erreur lors de la récupération des ordonnances');
  }

  Future<String> savePdf(
      String medecinId, String ordonnanceId, Uint8List pdfBytes) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$backendBaseUrl/api/pdfs/save'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'pdf',
          pdfBytes,
          contentType: MediaType('application', 'pdf'),
          filename: 'ordonnance.pdf',
        ),
      );

      request.fields['medecin_id'] = medecinId;
      request.fields['ordonnance_id'] = ordonnanceId;

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = json.decode(responseData);

      if (response.statusCode == 201) {
        return jsonData['filename'];
      }
      throw Exception(jsonData['error']);
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde du PDF: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getMedecinPdfs(String medecinId) async {
    final response = await http.get(
      Uri.parse('$backendBaseUrl/api/pdfs/medecin/$medecinId'),
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Erreur lors de la récupération des PDFs');
  }

  Future<Uint8List> downloadPdf(String filename) async {
    final response = await http.get(
      Uri.parse('$backendBaseUrl/api/pdfs/download/$filename'),
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    throw Exception('Erreur lors du téléchargement du PDF');
  }

  Future<List<Map<String, dynamic>>> getMedecinOrdonnances(
      String medecinId) async {
    try {
      print("Fetching ordonnances for medecin: $medecinId");
      final response = await http.get(
        Uri.parse('$baseUrl/ordonnances/medecin/$medecinId/ordonnances'),
        headers: Constants.headers,
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print("Error in API service: $e");
      throw Exception('Erreur de connexion: $e');
    }
  }

  Future<String> saveOrdonnancePdf(
      String ordonnanceId, Uint8List pdfBytes) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$backendBaseUrl/ordonnances/$ordonnanceId/pdf'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'pdf',
          pdfBytes,
          contentType: MediaType('application', 'pdf'),
          filename: 'ordonnance.pdf',
        ),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = json.decode(responseData);

      if (response.statusCode == 201) {
        return jsonData['filename'];
      }
      throw Exception(jsonData['error']);
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde du PDF: $e');
    }
  }

  Future<Uint8List?> getOrdonnancePdf(String ordonnanceId) async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.apiBaseUrl}/api/ordonnances/$ordonnanceId/pdf'),
        headers: Constants.headers,
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      print("Failed to get PDF: ${response.statusCode}");
      return null;
    } catch (e) {
      print("Error getting PDF: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> getMedecinOrdonnance(
      String ordonnanceId) async {
    try {
      print("Fetching ordonnance: $ordonnanceId");
      final response = await http.get(
        Uri.parse('$backendBaseUrl/ordonnances/$ordonnanceId'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error getting ordonnance: $e');
      return null;
    }
  }

  Future<Uint8List?> generatePdfFromData(
      Map<String, dynamic> ordonnance) async {
    try {
      final response = await http.post(
        Uri.parse('$backendBaseUrl/generate-pdf'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(ordonnance),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      print('Error generating PDF: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getSingleOrdonnance(String ordonnanceId) async {
    try {
      print("Fetching ordonnance: $ordonnanceId");
      final response = await http.get(
        Uri.parse('$backendBaseUrl/ordonnances/$ordonnanceId'), // Updated path
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      print(
          'Failed to get ordonnance: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('Error getting ordonnance: $e');
      return null;
    }
  }

  bool isValidEmail(String email) {
    final emailRegExp = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
    return emailRegExp.hasMatch(email);
  }

  Future<Map<String, String>> getPatientEmail(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('$backendBaseUrl/patients/$patientId/email'),
      );

      if (response.statusCode == 200) {
        return Map<String, String>.from(json.decode(response.body));
      }
      return {};
    } catch (e) {
      print('Error getting patient email: $e');
      return {};
    }
  }

  Future<bool> sendOrdonnancePdf(
      String emailAddress, Uint8List pdfBytes, String patientId) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/ordonnance_$patientId.pdf');
      await file.writeAsBytes(pdfBytes);

      final email = Email(
        body: 'Veuillez trouver ci-joint votre ordonnance médicale.',
        subject: 'Votre ordonnance médicale',
        recipients: [emailAddress],
        attachmentPaths: [file.path],
      );

      await FlutterEmailSender.send(email);
      await file.delete();
      return true;
    } catch (e) {
      print('Error sending PDF: $e');
      return false;
    }
  }

  String _extractDosageInfo(Map<String, dynamic> openfda) {
    try {
      // Récupérer les informations de dosage de différentes sources de l'API OpenFDA
      final dosageForm = _getFirstValue(openfda['dosage_form']);
      final strength = _getFirstValue(openfda['strength']);
      final route = _getFirstValue(openfda['route']);

      // Combiner les informations disponibles
      final List<String> dosageInfo = [];
      if (strength != null) dosageInfo.add(strength);
      if (dosageForm != null) dosageInfo.add(dosageForm);
      if (route != null) dosageInfo.add("voie $route");

      return dosageInfo.isNotEmpty ? dosageInfo.join(' - ') : '';
    } catch (e) {
      print('Erreur extraction dosage: $e');
      return '';
    }
  }

  String? _getListValues(dynamic list) {
    if (list is List) {
      return list.join(', ');
    }
    return null;
  }

  List<Medicament> _getUniqueMedicaments(List<Medicament> medicaments) {
    final uniqueMeds = <String, Medicament>{};
    for (var med in medicaments) {
      if (!uniqueMeds.containsKey(med.name)) {
        uniqueMeds[med.name] = med;
      }
    }
    return uniqueMeds.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }
}
