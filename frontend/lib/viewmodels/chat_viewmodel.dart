import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:medicare/components/chat_dialog.dart';
import '../services/gemini_service.dart';

class ChatViewModel extends ChangeNotifier {
  final GeminiService _geminiService = GeminiService();

  bool _isLoading = false;
  String _error = '';
  List<ChatMessage> _messages = [];
  File? _selectedImage;

  bool get isLoading => _isLoading;
  String get error => _error;
  List<ChatMessage> get messages => _messages;
  File? get selectedImage => _selectedImage;

  void setImage(File? image) {
    _selectedImage = image;
    notifyListeners();
  }

  void clearSelectedImage() {
    _selectedImage = null;
    notifyListeners();
  }

  Future<void> sendMessage(String message) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Add user message with image if available
      final userMessage = ChatMessage(
        id: DateTime.now().toString(),
        content: message,
        isBot: false,
        timestamp: DateTime.now(),
        imageFile: _selectedImage,
      );
      _messages.add(userMessage);
      notifyListeners();

      // Get AI response
      String aiResponse;
      try {
        if (_selectedImage != null) {
          // Convert image to bytes
          final imageBytes = await _selectedImage!.readAsBytes();

          // Get response with image
          aiResponse = await _geminiService.getMedicalResponseWithImage(
              message, imageBytes);

          // Clear the image after sending
          _selectedImage = null;
        } else {
          // Text-only response
          aiResponse = await _geminiService.getMedicalResponse(message);
        }
      } catch (e) {
        aiResponse =
            "I apologize, but I'm having trouble generating a response right now. Please try again in a moment.";
        _error = e.toString();
      }

      // Add AI message
      final aiMessage = ChatMessage(
        id: DateTime.now().toString(),
        content: aiResponse,
        isBot: true,
        timestamp: DateTime.now(),
        imageFile: null,
      );
      _messages.add(aiMessage);
    } catch (e) {
      _error = 'Error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }
}
