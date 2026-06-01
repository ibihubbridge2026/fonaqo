import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/config/api_config.dart';
import '../../../core/services/chat_service.dart';
import '../chat_repository.dart';

/// Écran de liste des conversations (Inbox)
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatRepository _chatRepository = ChatRepository();
  final ChatService _chatService = ChatService();
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _setupWebSocketListener();
  }

  @override
  void dispose() {
    _chatService.disconnect();
    super.dispose();
  }

  void _setupWebSocketListener() {
    // Listen for new messages via WebSocket to update list in real-time
    _chatService.messageStream.listen((message) {
      if (mounted) {
        _loadConversations(); // Reload to get updated order
      }
    });
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final conversations = await _chatRepository.fetchMyConversations();
      if (mounted) {
        setState(() {
          _conversations = conversations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _formatLastMessageTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'À l\'instant';
    if (difference.inMinutes < 60) return 'Il y a ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'Il y a ${difference.inHours}h';
    if (difference.inDays == 1) return 'Hier';
    if (difference.inDays < 7) return 'Il y a ${difference.inDays}j';

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatLastMessage(Map<String, dynamic>? message) {
    if (message == null) return 'Aucun message';

    final messageType = message['message_type'] ?? 'text';
    if (messageType == 'image') return '[Image]';
    if (messageType == 'voice') return '[Mémo vocal]';
    if (messageType == 'file') return '[Fichier]';

    final content = message['content'] as String?;
    if (content == null || content.isEmpty) return '...';

    return content.length > 50 ? '${content.substring(0, 50)}...' : content;
  }

  int _getUnreadCount(Map<String, dynamic> conversation) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAgent = authProvider.currentUser?.isAgent ?? false;

    if (isAgent) {
      return conversation['unread_count_agent'] ?? 0;
    } else {
      return conversation['unread_count_client'] ?? 0;
    }
  }

  String _getOtherUserName(Map<String, dynamic> conversation) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.id;

    final client = conversation['client'] as Map<String, dynamic>?;
    final agent = conversation['agent'] as Map<String, dynamic>?;

    if (client != null && client['id'] != currentUserId) {
      return client['username'] ?? client['first_name'] ?? 'Client';
    }

    if (agent != null && agent['id'] != currentUserId) {
      return agent['username'] ?? agent['first_name'] ?? 'Agent';
    }

    return 'Inconnu';
  }

  String? _getOtherUserAvatar(Map<String, dynamic> conversation) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.id;

    final client = conversation['client'] as Map<String, dynamic>?;
    final agent = conversation['agent'] as Map<String, dynamic>?;

    if (client != null && client['id'] != currentUserId) {
      return client['avatar_url'];
    }

    if (agent != null && agent['id'] != currentUserId) {
      return agent['avatar_url'];
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: const CustomAppBar.detailStack(title: 'Discussion'),
      body: RefreshIndicator(
        onRefresh: _loadConversations,
        color: const Color(0xFFFFD400),
        backgroundColor: Colors.white,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFFD400),
                ),
              )
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'Erreur de chargement',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : _conversations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune conversation',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _conversations.length,
                        itemBuilder: (context, index) {
                          final conversation = _conversations[index];
                          final lastMessage = conversation['last_message']
                              as Map<String, dynamic>?;
                          final lastMessageTime =
                              conversation['last_message_at'] != null
                                  ? DateTime.parse(
                                      conversation['last_message_at'])
                                  : null;
                          final unreadCount = _getUnreadCount(conversation);
                          final userName = _getOtherUserName(conversation);
                          final userAvatar = _getOtherUserAvatar(conversation);

                          return _ChatPreviewCard(
                            userName: userName,
                            userAvatar: userAvatar,
                            lastMessage: _formatLastMessage(lastMessage),
                            lastMessageTime:
                                _formatLastMessageTime(lastMessageTime),
                            unreadCount: unreadCount,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/chat-detail',
                                arguments: {
                                  'conversationId': conversation['id'],
                                  'userName': userName,
                                },
                              );
                            },
                          );
                        },
                      ),
      ),
    );
  }
}

class _ChatPreviewCard extends StatelessWidget {
  final String userName;
  final String? userAvatar;
  final String lastMessage;
  final String lastMessageTime;
  final int unreadCount;
  final VoidCallback onTap;

  const _ChatPreviewCard({
    required this.userName,
    required this.userAvatar,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey[200],
              backgroundImage: userAvatar != null
                  ? CachedNetworkImageProvider(userAvatar!) as ImageProvider
                  : null,
              child: userAvatar == null
                  ? Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        lastMessageTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD400),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : unreadCount.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
