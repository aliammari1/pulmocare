import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class VoiceDictationPanel extends StatefulWidget {
  final Function(String) onTextGenerated;
  final bool isDictating;
  final VoidCallback onToggleDictation;

  const VoiceDictationPanel({
    super.key,
    required this.onTextGenerated,
    required this.isDictating,
    required this.onToggleDictation,
  });

  @override
  State<VoiceDictationPanel> createState() => _VoiceDictationPanelState();
}

class _VoiceDictationPanelState extends State<VoiceDictationPanel> {
  late final stt.SpeechToText _speech;
  late final FlutterTts _flutterTts;
  bool _speechEnabled = false;
  String _lastWords = '';
  String _error = '';
  double _confidence = 0.0;
  bool _isInitializing = true;
  String _selectedLanguage = 'en-US';
  bool _isBrowserSupported = true;

  static const List<Map<String, String>> _availableLanguages = [
    {'code': 'en-US', 'name': 'English (US)'},
    {'code': 'fr-FR', 'name': 'French'},
    {'code': 'es-ES', 'name': 'Spanish'},
    {'code': 'de-DE', 'name': 'German'},
    {'code': 'it-IT', 'name': 'Italian'},
    {'code': 'ar-SA', 'name': 'Arabic'},
  ];

  @override
  void initState() {
    super.initState();
    _checkPlatformSupport();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initSpeech();
    _initTts();
  }

  void _checkPlatformSupport() {
    // This is a simplified version that will work on all platforms
    // In a real app, you would check specific capabilities based on platform
    setState(() {
      _isBrowserSupported = true;
    });
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage(_selectedLanguage);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      // Check if device supports TTS
      final voices = await _flutterTts.getVoices;
      if (voices == null || (voices is List && voices.isEmpty)) {
        throw Exception('No TTS voices available');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Text-to-speech not fully supported on this device: $e';
        });
      }
    }
  }

  Future<void> _initSpeech() async {
    if (!_isBrowserSupported) {
      setState(() {
        _isInitializing = false;
        _error = 'Speech recognition is not supported on this device';
      });
      return;
    }

    try {
      _speechEnabled = await _speech.initialize(
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (status == 'done' && mounted) {
            setState(() {
              widget.onToggleDictation();
            });
          }
        },
        onError: (errorNotification) {
          debugPrint('Speech error: $errorNotification');
          if (mounted) {
            setState(() {
              _error = _getFriendlyError(errorNotification.errorMsg);
              widget.onToggleDictation();
            });
          }
        },
        debugLogging: true,
      );

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      debugPrint('Speech initialization error: $e');
      if (mounted) {
        setState(() {
          _error = _getFriendlyError(e.toString());
          _isInitializing = false;
          _speechEnabled = false;
        });
      }
    }
  }

  String _getFriendlyError(String error) {
    if (error.contains('permission')) {
      return 'Please allow microphone access permission';
    } else if (error.contains('network')) {
      return 'Network error. Please check your internet connection';
    } else if (error.contains('no-speech')) {
      return 'No speech detected. Please try again';
    } else {
      return 'Error: $error';
    }
  }

  // Fix: Using the correct import with namespace
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
      if (result.finalResult) {
        widget.onTextGenerated(_lastWords);
      }
      if (result.hasConfidenceRating && result.confidence > 0) {
        _confidence = result.confidence;
      }
    });
  }

  Future<void> _startListening() async {
    try {
      // Using SpeechListenOptions instead of individual parameters
      await _speech.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: _selectedLanguage,
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _stopListening() async {
    try {
      await _speech.stop();
      if (_lastWords.isNotEmpty && mounted) {
        widget.onTextGenerated(_lastWords);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error stopping voice recognition: $e';
      });
    }
  }

  Future<void> _speakText(String text) async {
    try {
      await _flutterTts.setLanguage(_selectedLanguage);
      await _flutterTts.speak(text);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error playing speech: $e';
      });
    }
  }

  @override
  void dispose() {
    _speech.cancel();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Voice Dictation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                DropdownButton<String>(
                  value: _selectedLanguage,
                  items: _availableLanguages
                      .map((lang) => DropdownMenuItem(
                            value: lang['code'],
                            child: Text(lang['name']!),
                          ))
                      .toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null && mounted) {
                      setState(() {
                        _selectedLanguage = newValue;
                      });
                      _initTts();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!_isBrowserSupported)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Voice recognition is not fully supported on this device.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              )
            else if (_isInitializing)
              const CircularProgressIndicator()
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      widget.isDictating ? Icons.mic : Icons.mic_none,
                      color: widget.isDictating ? Colors.red : null,
                    ),
                    onPressed: _speechEnabled
                        ? () {
                            widget.onToggleDictation();
                            if (widget.isDictating) {
                              _startListening();
                            } else {
                              _stopListening();
                            }
                          }
                        : null,
                    tooltip: widget.isDictating
                        ? 'Stop Dictation'
                        : 'Start Dictation',
                  ),
                  if (widget.isDictating)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: LinearProgressIndicator(
                          value: _confidence,
                          backgroundColor: Colors.grey[200],
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ),
                    ),
                ],
              ),
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  _error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
            if (_lastWords.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Last dictation: $_lastWords',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.volume_up),
                    label: const Text('Play'),
                    onPressed: () => _speakText(_lastWords),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear'),
                    onPressed: () {
                      if (mounted) {
                        setState(() {
                          _lastWords = '';
                          _confidence = 0.0;
                          _error = '';
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
