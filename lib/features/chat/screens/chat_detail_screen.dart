import 'dart:async';

import 'package:flutter/material.dart';

import '../../../widgets/custom_app_bar.dart';
import '../models/chat_message.dart';

/// Écran de détail d'une conversation
class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String userName;
  final String? agentAvatar;
  final String? missionId;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.userName,
    this.agentAvatar,
    this.missionId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  static final Map<String, List<ChatMessage>> _chatHistory = {};

  /// Génère un ID de conversation unique basé sur les participants
  String _generateChatId() {
    // Si un missionId est disponible, l'utiliser comme base
    if (widget.missionId != null) {
      return 'mission_${widget.missionId}';
    }

    // Si le chatId contient déjà un missionId, l'utiliser directement
    if (widget.chatId.startsWith('mission_')) {
      return widget.chatId;
    }

    // Sinon, utiliser le chatId fourni qui devrait être unique
    return widget.chatId;
  }

  List<ChatMessage> get _messages {
    final chatId = _generateChatId();
    if (!_chatHistory.containsKey(chatId)) {
      // Créer une conversation vide pour chaque chat unique
      _chatHistory[chatId] = [];
    }
    return _chatHistory[chatId]!;
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final chatId = _generateChatId();
    setState(() {
      _chatHistory[chatId]!.add(ChatMessage.fromUser(
        text: text,
        chatId: chatId,
        senderId: 'current_user', // TODO: Get from AuthProvider
        senderName: 'Moi', // TODO: Get from AuthProvider
      ));
    });

    _messageController.clear();

    // Faire défiler vers le bas pour voir le nouveau message
    Future.delayed(const Duration(milliseconds: 100), () {
      // Scroll to bottom logic would go here if we had a scroll controller
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: CustomAppBar.detailStack(
        title: widget.userName,
        detailTitleWidget: Row(
          children: [
            if (widget.agentAvatar != null)
              CircleAvatar(
                radius: 16,
                backgroundImage:
                    NetworkImage(widget.agentAvatar!) as ImageProvider,
                backgroundColor: Colors.grey[200],
                child: widget.agentAvatar == null
                    ? const Icon(Icons.person, color: Colors.black54, size: 16)
                    : null,
              )
            else
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[200],
                child:
                    const Icon(Icons.person, color: Colors.black54, size: 16),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.userName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Zone de saisie
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Écrivez votre message...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(12),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD400),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: Row(
        mainAxisAlignment:
            message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: const Icon(
                Icons.person,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Bulle de message
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    message.isMe ? const Color(0xFFFFD400) : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isMe ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (message.isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: const Icon(
                Icons.person,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
