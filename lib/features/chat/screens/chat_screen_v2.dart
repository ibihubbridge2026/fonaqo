import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fonaco/features/chat/providers/chat_provider.dart';
import 'package:fonaco/features/chat/providers/presence_provider.dart';
import 'package:fonaco/features/chat/models/chat_room.dart';
import 'package:fonaco/features/chat/models/enums.dart';
import 'package:fonaco/features/chat/widgets/message_bubble.dart';
import 'package:fonaco/features/chat/widgets/typing_indicator.dart';
import 'package:fonaco/features/chat/services/chat_image_service.dart';
import 'package:fonaco/features/chat/services/audio_recorder_service.dart';

/// Écran de chat principal style WhatsApp
class ChatScreenV2 extends StatefulWidget {
  final String? conversationId;
  final String? missionId;

  const ChatScreenV2({
    super.key,
    this.conversationId,
    this.missionId,
  });

  @override
  State<ChatScreenV2> createState() => _ChatScreenV2State();
}

class _ChatScreenV2State extends State<ChatScreenV2> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatImageService _imageService = ChatImageService();
  final AudioRecorderService _audioService = AudioRecorderService();

  bool _isRecording = false;
  int _recordingDuration = 0;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final presenceProvider =
        Provider.of<PresenceProvider>(context, listen: false);

    // Connecter WebSocket
    await chatProvider.connectWebSocket(context);

    // Charger les conversations
    await chatProvider.loadConversations(context);

    // Démarrer le cleanup de présence
    presenceProvider.startCleanup();

    // Si conversationId fourni, la sélectionner
    if (widget.conversationId != null) {
      final conversation = chatProvider.conversations.firstWhere(
          (c) => c.id == widget.conversationId,
          orElse: () => chatProvider.conversations.first);
      if (conversation.id.isNotEmpty) {
        chatProvider.selectConversation(conversation);
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioService.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.sendTextMessage(text);

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage() async {
    final file = await _imageService.pickImageFromGallery();
    if (file == null) return;

    final compressed = await _imageService.compressImage(file.path);
    if (compressed == null) return;

    // TODO: Upload et envoyer message image
  }

  Future<void> _captureImage() async {
    final file = await _imageService.captureImage();
    if (file == null) return;

    final compressed = await _imageService.compressImage(file.path);
    if (compressed == null) return;

    // TODO: Upload et envoyer message image
  }

  Future<void> _pickFile() async {
    // TODO: Implémenter file picker
  }

  Future<void> _startRecording() async {
    final hasPermission = await _audioService.requestPermission();
    if (!hasPermission) return;

    final path = await _audioService.startRecording();
    if (path != null) {
      setState(() {
        _isRecording = true;
      });

      // Écouter la durée
      _audioService.durationStream.listen((duration) {
        if (mounted) {
          setState(() {
            _recordingDuration = duration;
          });
        }
      });
    }
  }

  Future<void> _stopRecording() async {
    final file = await _audioService.stopRecording();
    if (file != null) {
      // TODO: Upload et envoyer message audio
    }

    setState(() {
      _isRecording = false;
      _recordingDuration = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5DDD5), // WhatsApp background
      appBar: _buildAppBar(),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.currentConversation == null) {
            return _buildConversationList(chatProvider);
          }
          return _buildChatView(chatProvider);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF075E54), // WhatsApp green
      elevation: 0,
      title: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          final conversation = chatProvider.currentConversation;
          final otherParticipant = conversation != null
              ? conversation
                  .getOtherParticipant('current_user') // TODO: Get real user ID
              : null;

          if (otherParticipant == null) {
            return const Text('Chat');
          }

          return Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[300],
                backgroundImage: otherParticipant.avatar != null
                    ? CachedNetworkImageProvider(otherParticipant.avatar!)
                    : null,
                child: otherParticipant.avatar == null
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherParticipant.userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Consumer<PresenceProvider>(
                      builder: (context, presenceProvider, child) {
                        final isOnline =
                            presenceProvider.isOnline(otherParticipant.userId);
                        return Text(
                          isOnline
                              ? 'En ligne'
                              : presenceProvider
                                  .formatLastSeen(otherParticipant.userId),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam),
          onPressed: () {
            // TODO: Appel vidéo
          },
        ),
        IconButton(
          icon: const Icon(Icons.call),
          onPressed: () {
            // TODO: Appel vocal
          },
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'view_contact') {
              // TODO: Voir contact
            } else if (value == 'clear_chat') {
              // TODO: Effacer conversation
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
                value: 'view_contact', child: Text('Voir contact')),
            const PopupMenuItem(
                value: 'clear_chat', child: Text('Effacer conversation')),
          ],
        ),
      ],
    );
  }

  Widget _buildConversationList(ChatProvider chatProvider) {
    if (chatProvider.isLoadingConversations) {
      return const Center(child: CircularProgressIndicator());
    }

    if (chatProvider.conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucune conversation',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: chatProvider.conversations.length,
      itemBuilder: (context, index) {
        final conversation = chatProvider.conversations[index];
        return _buildConversationTile(conversation, chatProvider);
      },
    );
  }

  Widget _buildConversationTile(
      ChatRoom conversation, ChatProvider chatProvider) {
    final otherParticipant = conversation
        .getOtherParticipant('current_user'); // TODO: Get real user ID

    return ListTile(
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: Colors.grey[300],
        backgroundImage: otherParticipant?.avatar != null
            ? CachedNetworkImageProvider(otherParticipant!.avatar!)
            : null,
        child: otherParticipant?.avatar == null
            ? const Icon(Icons.person, color: Colors.white)
            : null,
      ),
      title: Text(
        otherParticipant?.userName ?? conversation.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Row(
        children: [
          if (conversation.lastMessage != null) ...[
            if (conversation.lastMessage!.status == MessageStatus.read)
              const Icon(Icons.done_all, size: 14, color: Colors.blue),
            if (conversation.lastMessage!.status == MessageStatus.delivered)
              const Icon(Icons.done_all, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                conversation.lastMessage!.content ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (conversation.lastMessage != null)
            Text(
              _formatTime(conversation.lastMessage!.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: conversation.unreadCount > 0
                    ? const Color(0xFF075E54)
                    : Colors.grey[600],
              ),
            ),
          if (conversation.unreadCount > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF075E54),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                conversation.unreadCount > 99
                    ? '99+'
                    : conversation.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: () {
        chatProvider.selectConversation(conversation);
      },
    );
  }

  Widget _buildChatView(ChatProvider chatProvider) {
    return Column(
      children: [
        // Typing indicator
        Consumer<ChatProvider>(
          builder: (context, chatProvider, child) {
            final typingUsers = chatProvider.typingUsers;
            if (typingUsers.isEmpty) return const SizedBox.shrink();

            final typingUserId = typingUsers.keys.first;
            final conversation = chatProvider.currentConversation;
            final participant = conversation?.participants.firstWhere(
              (p) => p.userId == typingUserId,
              orElse: () => conversation.participants.first,
            );

            return TypingIndicator(
              userName: participant?.userName ?? 'Utilisateur',
              isTyping: true,
            );
          },
        ),

        // Messages list
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: chatProvider.currentMessages.length,
            itemBuilder: (context, index) {
              final message = chatProvider.currentMessages[index];
              final isMe =
                  message.senderId == 'current_user'; // TODO: Get real user ID
              return MessageBubble(
                message: message,
                isMe: isMe,
                onTap: () {
                  // TODO: Actions sur message
                },
                onLongPress: () {
                  // TODO: Menu contextuel
                },
              );
            },
          ),
        ),

        // Input area
        _buildInputArea(chatProvider),
      ],
    );
  }

  Widget _buildInputArea(ChatProvider chatProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_isRecording) ...[
            // Recording UI
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      const Text('Enregistrement...'),
                      Text(
                        AudioRecorderService.formatDuration(_recordingDuration),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _stopRecording,
                ),
              ],
            ),
          ] else ...[
            // Normal input
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.emoji_emotions_outlined),
                  onPressed: () {
                    // TODO: Emoji picker
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                    onChanged: (text) {
                      chatProvider.updateTypingStatus(text.isNotEmpty);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: () {
                    _showAttachmentBottomSheet();
                  },
                ),
                if (_messageController.text.isEmpty)
                  IconButton(
                    icon: const Icon(Icons.mic),
                    onPressed: _startRecording,
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showAttachmentBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Image'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Caméra'),
              onTap: () {
                Navigator.pop(context);
                _captureImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('Document'),
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 24) {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return [
        'Lun',
        'Mar',
        'Mer',
        'Jeu',
        'Ven',
        'Sam',
        'Dim'
      ][timestamp.weekday - 1];
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}
