import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VoiceRecognitionService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  Future<bool> initialize() async {
    if (!_isInitialized) {
      try {
        _isInitialized = await _speech.initialize(
          debugLogging: true,
          onError: (errorNotification) =>
              print('Error: ${errorNotification.errorMsg}'),
          onStatus: (status) => print('Status: $status'),
        );
      } catch (e) {
        print('Error initializing speech recognition: $e');
        _isInitialized = false;
      }
    }
    return _isInitialized;
  }

  Future<void> startListening(
    Function(String) onResult, {
    String? localeId,
    Duration? listenFor,
    Duration? pauseFor,
  }) async {
    if (!_isInitialized) await initialize();

    if (_speech.isAvailable) {
      try {
        await _speech.listen(
          onResult: (result) {
            if (result.finalResult) {
              onResult(result.recognizedWords);
            }
          },
          localeId: localeId ?? 'fr_FR',
          listenFor: listenFor ?? const Duration(seconds: 30),
          pauseFor: pauseFor ?? const Duration(seconds: 3),
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
        );
      } catch (e) {
        print('Error starting speech recognition: $e');
      }
    }
  }

  void stopListening() {
    try {
      _speech.stop();
    } catch (e) {
      print('Error stopping speech recognition: $e');
    }
  }

  bool get isListening => _speech.isListening;

  Future<bool> checkPermission() async {
    try {
      if (!_isInitialized) {
        _isInitialized = await _speech.initialize(
          onError: (error) => print('Error: $error'),
          onStatus: (status) => print('Status: $status'),
          debugLogging: true,
        );
      }

      // Vérifie explicitement la permission
      final hasPermission = await _speech.hasPermission;
      return hasPermission;
    } on PlatformException catch (e) {
      print('Permission error: ${e.message}');
      return false;
    } catch (e) {
      print('Error checking permission: $e');
      return false;
    }
  }
}
