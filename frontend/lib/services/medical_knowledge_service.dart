import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/medical_knowledge.dart';

class MedicalKnowledgeService {
  final String baseUrl;

  MedicalKnowledgeService({required this.baseUrl});

  Future<List<MedicalReference>> searchKnowledge(String query) async {
    debugPrint('Searching knowledge for: $query');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/knowledge/search'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint(
            'Received ${(data['results'] as List).length} knowledge results');
        return (data['results'] as List)
            .map((e) => MedicalReference.fromJson(e))
            .toList();
      } else {
        throw Exception(
            'Failed to search medical knowledge: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error searching knowledge: $e');
      throw Exception('Failed to search medical knowledge: $e');
    }
  }

  Future<ChatResponse> chatWithMedicalContext(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/knowledge/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200) {
        return ChatResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get chat response: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in medical chat: $e');
      throw Exception('Failed to get chat response: $e');
    }
  }

  Future<Map<String, dynamic>> analyzeXrayWithContext(
      List<int> imageBytes) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/xray/analyze'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'xray.jpg',
        ),
      );

      debugPrint('Sending X-ray analysis request to: ${request.url}');
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return jsonDecode(responseData);
      } else {
        throw Exception('Failed to analyze X-ray: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error analyzing X-ray: $e');
      throw Exception('Failed to analyze X-ray: $e');
    }
  }

  Future<Map<String, dynamic>> analyzeReport(String reportContent) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/knowledge/analyze-report'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'content': reportContent}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to analyze report: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error analyzing report: $e');
      throw Exception('Failed to analyze report: $e');
    }
  }

  Future<Uint8List?> generateMedicalDiagram(String description) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/diagram/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'description': description}),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        debugPrint('Failed to generate diagram: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error generating diagram: $e');
      return null;
    }
  }
}
