import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../widgets/custom_app_bar.dart';
import '../../../core/services/chat_websocket_service.dart';
import '../../../core/api/base_client.dart';
import '../../../core/providers/auth_provider.dart';

// Alias pour éviter le conflit
typedef ChatMessage = ChatWebSocketMessage;

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String userName;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.userName,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  late ChatWebSocketService _chatService;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _chatService = ChatWebSocketService();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatService.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    try {
      await _loadMessageHistory();

      await _chatService.connect(widget.chatId);

      _chatService.messageStream.listen((message) {
        if (mounted) {
          _scrollToBottom();
        }
      });

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erreur de connexion : $e';
        });
      }
    }
  }

  Future<void> _loadMessageHistory() async {
    try {
      final response = await BaseClient().dio.get(
        '/api/v1/chat/messages/',
        queryParameters: {
          'mission_id': widget.chatId,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> messagesData =
            response.data['results'] ?? [];

        final currentUsername =
            Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ).currentUser?.username ??
                '';

        for (final messageData in messagesData) {
          final message = ChatMessage.fromJson(
            messageData,
            currentUsername,
          );

          _chatService.addHistoricalMessage(message);
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement historique : $e');
    }
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty) return;

    try {
      await _chatService.sendMessage(text);

      _messageController.clear();

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur envoi message : $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: CustomAppBar.detailStack(
        title: widget.userName,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Text(_errorMessage!),
                      )
                    : ListenableBuilder(
                        listenable: _chatService,
                        builder: (context, _) {
                          return ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount:
                                _chatService.messages.length,
                            itemBuilder: (context, index) {
                              final message =
                                  _chatService.messages[index];

                              return _buildMessageBubble(
                                message,
                              );
                            },
                          );
                        },
                      ),
          ),

          _buildMessageInput(),
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
        mainAxisAlignment: message.isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
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

          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isMe
                    ? const Color(0xFFFFD400)
                    : Colors.grey[200],
                borderRadius:
                    BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: message.isMe
                          ? Colors.black
                          : Colors.black87,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
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

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey[300]!,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText:
                    'Écrivez votre message...',
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.all(12),
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
                borderRadius:
                    BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}