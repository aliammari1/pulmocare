import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';
import 'assistant_service.dart';

class ChatViewModel extends ChangeNotifier {
  ChatViewModel({AssistantService? assistant})
    : _assistant = assistant ?? AssistantService();

  final AssistantService _assistant;
  final List<ChatMessage> _messages = [];

  bool _isLoading = false;
  String _error = '';
  String? _disclaimer;
  String? _model;

  bool get isLoading => _isLoading;
  String get error => _error;
  String? get disclaimer => _disclaimer;
  String? get model => _model;
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  Future<bool> sendMessage(String message, {String? context}) async {
    final text = message.trim();
    if (text.isEmpty || _isLoading) return false;

    _error = '';
    _isLoading = true;
    _messages.add(
      ChatMessage(
        id: 'user-${DateTime.now().microsecondsSinceEpoch}',
        content: text,
        isAssistant: false,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();

    try {
      final reply = await _assistant.send(message: text, context: context);
      _model = reply.model;
      _disclaimer = reply.disclaimer;
      _messages.add(
        ChatMessage(
          id: 'assistant-${DateTime.now().microsecondsSinceEpoch}',
          content: reply.response,
          isAssistant: true,
          timestamp: DateTime.now(),
        ),
      );
      return true;
    } on DioException catch (error) {
      final data = error.response?.data;
      final detail = data is Map ? data['detail']?.toString() : null;
      _error = detail?.isNotEmpty == true
          ? detail!
          : 'The clinical assistant is temporarily unavailable.';
      return false;
    } catch (_) {
      _error = 'The clinical assistant is temporarily unavailable.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _messages.clear();
    _error = '';
    notifyListeners();
  }
}
