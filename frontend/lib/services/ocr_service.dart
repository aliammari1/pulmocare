import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

abstract class OcrService {
  String get name;
  Future<String> recognizeText(String imagePath);
}

class GoogleMLKitOcr implements OcrService {
  @override
  String get name => 'Reconnaissance Automatique';

  @override
  Future<String> recognizeText(String imagePath) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final inputImage = InputImage.fromFilePath(imagePath);
    final result = await textRecognizer.processImage(inputImage);
    textRecognizer.close();
    return result.text;
  }
}

class ManualOcrService implements OcrService {
  @override
  String get name => 'Saisie Manuelle';

  @override
  Future<String> recognizeText(String imagePath) async {
    return ''; // La saisie manuelle sera gérée par l'interface utilisateur
  }
}
