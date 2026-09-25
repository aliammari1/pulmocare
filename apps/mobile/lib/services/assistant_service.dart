import 'package:dio/dio.dart';

import '../utils/DioClient.dart';

class AssistantReply {
  const AssistantReply({
    required this.response,
    required this.model,
    required this.disclaimer,
  });

  final String response;
  final String model;
  final String disclaimer;

  factory AssistantReply.fromJson(Map<String, dynamic> json) {
    return AssistantReply(
      response: (json['response'] ?? '').toString(),
      model: (json['model'] ?? '').toString(),
      disclaimer: (json['disclaimer'] ?? '').toString(),
    );
  }
}

class AssistantService {
  AssistantService({Dio? dio}) : _dio = dio ?? DioHttpClient().dio;

  final Dio _dio;

  Future<AssistantReply> send({
    required String message,
    String? context,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'reports/ai/assistant',
      data: {
        'message': message.trim(),
        if (context != null && context.trim().isNotEmpty)
          'context': context.trim(),
      },
    );

    final reply = AssistantReply.fromJson(
      response.data ?? const <String, dynamic>{},
    );
    if (reply.response.isEmpty) {
      throw const FormatException('AI assistant returned an empty response');
    }
    return reply;
  }
}
