import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TranslationService {
  // Cache for storing translated text to avoid repeated API calls
  static final Map<String, Map<String, String>> _translationCache = {};

  // API key for Google Translate (you'll need to get your own)
  static const String apiKey = "YOUR_GOOGLE_TRANSLATE_API_KEY";

  // Base URL for Google Translate API
  static const String baseUrl =
      "https://translation.googleapis.com/language/translate/v2";

  // Method to translate text to a target language
  static Future<String> translateText(String text, String targetLanguage,
      {String sourceLanguage = 'en'}) async {
    // Don't translate if target is English or the text is empty
    if (text.isEmpty || targetLanguage == 'en') {
      return text;
    }

    // Check if translation is already cached
    if (_translationCache[targetLanguage]?.containsKey(text) ?? false) {
      return _translationCache[targetLanguage]![text]!;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl?key=$apiKey'),
        body: {
          'q': text,
          'source': sourceLanguage,
          'target': targetLanguage,
          'format': 'text',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final translations = data['data']['translations'] as List;
        final translatedText = translations.first['translatedText'] as String;

        // Cache the result
        _translationCache[targetLanguage] ??= {};
        _translationCache[targetLanguage]![text] = translatedText;

        return translatedText;
      } else {
        print('Translation API error: ${response.body}');
        return text; // Return original text if translation fails
      }
    } catch (e) {
      print('Translation error: $e');
      return text; // Return original text if translation fails
    }
  }

  // Load cached translations from shared preferences
  static Future<void> loadCachedTranslations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('translation_cache');
      if (cached != null) {
        final Map<String, dynamic> cachedData = json.decode(cached);

        cachedData.forEach((lang, translations) {
          _translationCache[lang] = Map<String, String>.from(translations);
        });
      }
    } catch (e) {
      print('Error loading translation cache: $e');
    }
  }

  // Save cached translations to shared preferences
  static Future<void> saveCachedTranslations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'translation_cache', json.encode(_translationCache));
    } catch (e) {
      print('Error saving translation cache: $e');
    }
  }
}
