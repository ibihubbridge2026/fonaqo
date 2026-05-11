import 'package:flutter/material.dart';

import '../../../widgets/custom_app_bar.dart';
import '../widgets/chat_preview_card.dart';

/// Écran de liste des conversations (Inbox)
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final List<ChatPreview> _chats = [
    ChatPreview(
      id: '1',
      userName: 'Marie Kouakou',
      userAvatar: 'assets/images/avatar/female_1.png',
      lastMessage: 'Super, je suis arrivée !',
      lastMessageTime: 'Il y a 5 min',
      unreadCount: 2,
      isOnline: true,
    ),
    ChatPreview(
      id: '2',
      userName: 'Paul Assaba',
      userAvatar: 'assets/images/avatar/male_1.png',
      lastMessage: 'Les documents sont prêts',
      lastMessageTime: 'Il y a 1h',
      unreadCount: 0,
      isOnline: false,
    ),
    ChatPreview(
      id: '3',
      userName: 'Service Client FONACO',
      userAvatar: 'assets/images/avatar/support.png',
      lastMessage: 'Votre mission a été acceptée',
      lastMessageTime: 'Hier',
      unreadCount: 1,
      isOnline: true,
      isSupport: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: const CustomAppBar.detailStack(title: 'Messages'),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _chats.length,
        itemBuilder: (context, index) {
          final chat = _chats[index];
          return ChatPreviewCard(
            chat: chat,
            onTap: () {
              Navigator.pushNamed(
                context,
                '/chat-detail',
                arguments: {'chatId': chat.id, 'userName': chat.userName},
              );
            },
          );
        },
      ),
    );
  }
}

/// Modèle pour l'aperçu d'une conversation
class ChatPreview {
  final String id;
  final String userName;
  final String userAvatar;
  final String lastMessage;
  final String lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final bool isSupport;

  const ChatPreview({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.isOnline,
    this.isSupport = false,
  });
}
