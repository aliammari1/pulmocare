import 'assistant_service.dart';

class AiService {
  AiService({AssistantService? assistant})
    : _assistant = assistant ?? AssistantService();

  final AssistantService _assistant;

  Future<Map<String, dynamic>> processText(
    String text, {
    String context = '',
  }) async {
    final reply = await _assistant.send(
      message:
          'Improve the following clinical text for clarity, grammar, and concise professional wording. Do not add facts that are not present. Return only the revised text.\n\n' +
          text,
      context: context,
    );
    return {
      'correctedText': reply.response,
      'suggestions': const <String>[],
      'model': reply.model,
      'disclaimer': reply.disclaimer,
    };
  }

  Future<Map<String, dynamic>> getChatbotResponse(
    String userInput,
    String reportContext,
  ) async {
    final reply = await _assistant.send(
      message: userInput,
      context: reportContext,
    );
    return {
      'response': reply.response,
      'model': reply.model,
      'disclaimer': reply.disclaimer,
    };
  }

  Future<Map<String, dynamic>> analyzeReport(String reportContent) async {
    final reply = await _assistant.send(
      message:
          'Review this draft clinical report for missing context, ambiguous wording, and internal inconsistencies. Do not diagnose or invent findings. Return a concise review for the clinician.',
      context: reportContent,
    );
    return {
      'analysis': reply.response,
      'suggestions': const <String>[],
      'model': reply.model,
      'disclaimer': reply.disclaimer,
    };
  }
}
