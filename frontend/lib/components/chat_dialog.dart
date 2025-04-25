import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../viewmodels/chat_viewmodel.dart';
import '../theme/app_theme.dart';
import '../utils/medical_prompts.dart';

class ChatMessage {
  final String id;
  final String content;
  final bool isBot;
  final DateTime timestamp;
  final String? imageUrl;
  final File? imageFile;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isBot,
    required this.timestamp,
    this.imageUrl,
    this.imageFile,
  });
}

class ChatDialog extends StatefulWidget {
  const ChatDialog({Key? key}) : super(key: key);

  @override
  _ChatDialogState createState() => _ChatDialogState();
}

class _ChatDialogState extends State<ChatDialog> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.only(
          left: message.isBot ? 8 : 50,
          right: message.isBot ? 50 : 8,
          top: 8,
          bottom: 8,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.isBot ? Colors.white : AppTheme.turquoise,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display image if available
            if (message.imageFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  message.imageFile!,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
            if (message.imageFile != null) const SizedBox(height: 8),

            if (message.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  message.imageUrl!,
                  height: 150,
                  width: 200,
                  fit: BoxFit.cover,
                ),
              ),
            if (message.imageUrl != null) const SizedBox(height: 8),

            Text(
              message.content,
              style: TextStyle(
                color: message.isBot ? Colors.black87 : Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: message.isBot ? Colors.grey : Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey[50]!,
            Colors.white,
          ],
        ),
      ),
      child: Consumer<ChatViewModel>(
        builder: (context, chatVM, child) {
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: chatVM.messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(chatVM.messages[index]);
                  },
                ),
              ),
              if (chatVM.isLoading)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.turquoise,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'AI is thinking...',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSelectedImagePreview(ChatViewModel chatVM) {
    if (chatVM.selectedImage == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.grey[100],
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              chatVM.selectedImage!,
              height: 60,
              width: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Image selected',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => chatVM.clearSelectedImage(),
            color: Colors.grey[600],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Consumer<ChatViewModel>(
      builder: (context, chatVM, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSelectedImagePreview(chatVM),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image_outlined,
                        color: AppTheme.turquoise),
                    onPressed: () => _pickImage(chatVM),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: chatVM.selectedImage != null
                            ? "Ask about this image..."
                            : MedicalPrompts.getRandomSuggestion(),
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      onSubmitted: (text) => _sendMessage(text, chatVM),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.turquoise,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () =>
                          _sendMessage(_messageController.text, chatVM),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage(ChatViewModel chatVM) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      chatVM.setImage(File(pickedFile.path));
      _scrollToBottom();
    }
  }

  void _sendMessage(String message, ChatViewModel chatVM) {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty && chatVM.selectedImage == null) return;

    // When sending only an image with no text, add a placeholder text
    final textToSend = trimmedMessage.isEmpty && chatVM.selectedImage != null
        ? "Please analyze this medical image"
        : trimmedMessage;

    chatVM.sendMessage(textToSend);
    _messageController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Medical AI Assistant',
          style: TextStyle(color: AppTheme.turquoise),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.turquoise),
          onPressed: () => Navigator.pop(context),
        ),
        iconTheme: const IconThemeData(color: AppTheme.turquoise),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildMessageInput(),
        ],
      ),
    );
  }
}
