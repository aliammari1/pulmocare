import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class KnowledgeService {
  final http.Client _client = http.Client();
  final Map<String, String> _headers = {'Content-Type': 'application/json'};
  final String _baseUrl = ApiConfig.knowledgeServiceUrl;

  Future<List<Map<String, dynamic>>> searchKnowledge(String query,
      {int k = 5}) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiConfig.knowledgeSearchUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'query': query,
          'k': k,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to search: ${json.decode(response.body)['error']}');
      }

      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['results']);
    } catch (e) {
      throw Exception('Error searching knowledge: $e');
    }
  }

  Future<Map<String, dynamic>> chat(String message) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiConfig.knowledgeChatUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'message': message}),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to chat: ${json.decode(response.body)['error']}');
      }

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Error in chat: $e');
    }
  }

  Future<List<Map<String, dynamic>>> extractEntities(String text) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiConfig.knowledgeEntitiesUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'text': text}),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to extract entities: ${json.decode(response.body)['error']}');
      }

      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['entities']);
    } catch (e) {
      throw Exception('Error extracting entities: $e');
    }
  }

  Future<List<String>> getRecommendations(String text) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/knowledge/recommendations'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'text': text}),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to get recommendations: ${json.decode(response.body)['error']}');
      }

      final data = json.decode(response.body);
      return List<String>.from(data['recommendations']);
    } catch (e) {
      throw Exception('Error getting recommendations: $e');
    }
  }

  Future<void> deleteReport(String id) async {
    try {
      final response = await _client.delete(
        Uri.parse('${ApiConfig.baseUrl}/reports/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to delete report: ${json.decode(response.body)['error']}');
      }
    } catch (e) {
      throw Exception('Error deleting report: $e');
    }
  }

  Future<Uint8List> exportReport(String id, {String format = 'pdf'}) async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/reports/$id/export?format=$format'),
        headers: {'Accept': 'application/pdf'},
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to export report: ${json.decode(response.body)['error']}');
      }

      return response.bodyBytes;
    } catch (e) {
      throw Exception('Error exporting report: $e');
    }
  }

  Future<Map<String, dynamic>> getConditionInfo(String condition) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/condition/$condition'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to get condition info: ${json.decode(response.body)['error']}');
      }

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Error getting condition info: $e');
    }
  }

  Future<List<Map<String, dynamic>>> searchConditions(String query) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/search/$query'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to search conditions: ${json.decode(response.body)['error']}');
      }

      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['results']);
    } catch (e) {
      throw Exception('Error searching conditions: $e');
    }
  }

  Future<Map<String, dynamic>> getReferences(String condition) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/references/$condition'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to get references: ${json.decode(response.body)['error']}');
      }

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Error getting references: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}
