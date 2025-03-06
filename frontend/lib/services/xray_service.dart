import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../services/api_config.dart';

class XRayService {
  final String baseUrl;
  final http.Client _client = http.Client();

  XRayService({required this.baseUrl});

  Future<Map<String, dynamic>> analyzeXRay(
      Uint8List imageBytes, String filename,
      [Map<String, dynamic>? metadata]) async {
    try {
      // Determine the file extension
      final fileExtension = filename.split('.').last.toLowerCase();
      final contentType = _getContentType(fileExtension);

      // Create multipart request
      final uri = Uri.parse(ApiConfig.xrayAnalyzeUrl);
      var request = http.MultipartRequest('POST', uri);

      // Add image file
      final multipartFile = http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: filename,
        contentType: contentType,
      );
      request.files.add(multipartFile);

      // Add metadata if provided
      if (metadata != null && metadata.isNotEmpty) {
        request.fields['metadata'] = json.encode(metadata);
      }

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception('Failed to analyze X-Ray: ${response.body}');
      }

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Error analyzing X-Ray: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getHistory(String patientId) async {
    try {
      final response = await _client.get(
        Uri.parse(ApiConfig.xrayHistoryUrl(patientId)),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get history: ${response.body}');
      }

      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['history']);
    } catch (e) {
      throw Exception('Error getting X-Ray history: $e');
    }
  }

  Future<Map<String, dynamic>> getAnalysisById(String analysisId) async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/xray/analysis/$analysisId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get analysis: ${response.body}');
      }

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Error getting analysis: $e');
    }
  }

  MediaType _getContentType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'dcm':
      case 'dicom':
        return MediaType('application', 'dicom');
      default:
        return MediaType('application', 'octet-stream');
    }
  }

  void dispose() {
    _client.close();
  }
}
