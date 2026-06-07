import 'package:flutter/material.dart';

import '../../../widgets/custom_app_bar.dart';
import '../../../core/services/chat_websocket_service.dart';
import '../chat_repository.dart';
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
  final List<ChatMessage> _messages = [];
  final ChatWebSocketService _wsService = ChatWebSocketService();
  final ChatRepository _repository = ChatRepository();
  bool _isConnected = false;
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _connectWebSocket();
  }

  @override
  void dispose() {
    _wsService.disconnect();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    if (widget.chatId.isEmpty) {
      print('ERROR: Cannot load history - chatId is empty');
      return;
    }

    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final messagesData =
          await _repository.fetchConversationMessages(widget.chatId);
      setState(() {
        _messages.clear();
        for (final msgData in messagesData) {
          final timestamp = msgData['created_at'] != null
              ? DateTime.parse(msgData['created_at'])
              : DateTime.now();
          final timeStr =
              '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
          _messages.add(ChatMessage(
            id: msgData['id']?.toString() ?? '',
            text: msgData['content']?.toString() ?? '',
            time: timeStr,
            senderId: msgData['sender']?.toString(),
            senderName: msgData['sender']?.toString(),
            isMe: msgData['sender']?.toString() ==
                'current_user', // TODO: Get from AuthProvider
            timestamp: timestamp,
          ));
        }
        _isLoadingHistory = false;
      });

      // Marquer messages comme lus
      await _repository.markMessagesAsRead(widget.chatId, markAll: true);
    } catch (e) {
      print('ERROR: Failed to load message history: $e');
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _connectWebSocket() async {
    if (widget.missionId == null) {
      print('ERROR: Cannot connect WebSocket - missionId is null');
      return;
    }

    try {
      await _wsService.connect(widget.missionId!);
      setState(() {
        _isConnected = true;
      });

      // Écouter les messages
      _wsService.messageStream.listen((message) {
        final now = message.timestamp;
        final timeStr =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        setState(() {
          _messages.add(ChatMessage(
            id: message.id,
            text: message.content,
            time: timeStr,
            senderId: message.sender,
            senderName: message.sender,
            isMe: message.isMe,
            timestamp: message.timestamp,
          ));
        });
      });
    } catch (e) {
      print('ERROR: WebSocket connection failed: $e');
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (!_isConnected) {
      print('ERROR: Cannot send message - WebSocket not connected');
      return;
    }

    try {
      _wsService.sendMessage(text);
      _messageController.clear();
    } catch (e) {
      print('ERROR: Failed to send message: $e');
    }
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
          if (_isLoadingHistory)
            const Center(child: CircularProgressIndicator())
          else if (_messages.isEmpty)
            const Center(child: Text('Aucun message'))
          else
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
