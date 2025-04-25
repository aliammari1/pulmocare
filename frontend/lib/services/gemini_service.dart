import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // Replace with your actual API key from Google AI Studio
  static const String apiKey = '***REMOVED-SECRET***';
  late final GenerativeModel model;

  GeminiService() {
    // Use a single model for both text and image processing
    model = GenerativeModel(
      model: 'gemini-2.0-flash', // Using only gemini-2.0-flash for everything
      apiKey: apiKey,
    );
  }

  final String medicalContext = '''
    You are an AI medical assistant helping doctors. Your responses should:
    - Be professional and medical-oriented
    - Include relevant medical terminology when appropriate
    - Reference medical guidelines when possible
    - Suggest evidence-based practices
    - Maintain patient confidentiality
    - Remind that final decisions rest with the healthcare provider
    ''';

  Future<String> getMedicalResponse(String prompt) async {
    try {
      final content = [
        Content.text('$medicalContext\n\nQuestion: $prompt'),
      ];

      final response = await model.generateContent(content);
      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        throw Exception('Empty response from Gemini API');
      }

      return responseText;
    } catch (e) {
      print('Gemini API Error: $e'); // Add logging for debugging
      throw Exception('Failed to get AI response: $e');
    }
  }

  Future<String> getMedicalResponseWithImage(
      String prompt, Uint8List imageBytes) async {
    try {
      // Create Parts using the correct API for gemini-2.0-flash
      final textPart = TextPart(
          '$medicalContext\n\nAnalyze this medical image and answer: $prompt');
      final imagePart = DataPart('image/jpeg', imageBytes);

      final content = Content.multi([textPart, imagePart]);

      // Use the same model for image analysis
      final response = await model.generateContent([content]);
      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        throw Exception('Empty response from Gemini API for image analysis');
      }

      return responseText;
    } catch (e) {
      print('Gemini Image API Error: $e'); // Add logging for debugging
      throw Exception('Failed to get image analysis: $e');
    }
  }
}
