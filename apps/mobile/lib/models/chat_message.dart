class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.content,
    required this.isAssistant,
    required this.timestamp,
  });

  final String id;
  final String content;
  final bool isAssistant;
  final DateTime timestamp;
}
