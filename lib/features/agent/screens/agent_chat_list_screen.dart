import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../widgets/agent_custom_header.dart';
import 'agent_chat_screen.dart';

class AgentChatListScreen extends StatefulWidget {
  const AgentChatListScreen({super.key});

  @override
  State<AgentChatListScreen> createState() => _AgentChatListScreenState();
}

class _AgentChatListScreenState extends State<AgentChatListScreen> {
  // Liste des conversations simulées
  final List<Map<String, dynamic>> _conversations = [
    {
      'id': '1',
      'name': 'Jean Client',
      'lastMessage': 'Je suis en route pour la mission',
      'time': '08:30',
      'unreadCount': 2,
      'avatar': 'https://i.pravatar.cc/100?img=1',
      'isOnline': true,
    },
    {
      'id': '2',
      'name': 'Marie Commanditaire',
      'lastMessage': 'Merci pour votre service',
      'time': 'Hier',
      'unreadCount': 0,
      'avatar': 'https://i.pravatar.cc/100?img=5',
      'isOnline': false,
    },
    {
      'id': '3',
      'name': 'Paul Support',
      'lastMessage': 'Votre paiement a été traité',
      'time': '14:20',
      'unreadCount': 1,
      'avatar': 'https://i.pravatar.cc/100?img=3',
      'isOnline': true,
    },
    {
      'id': '4',
      'name': 'Sophie Client',
      'lastMessage': 'Pouvez-vous me donner une estimation?',
      'time': '2 jours',
      'unreadCount': 0,
      'avatar': 'https://i.pravatar.cc/100?img=9',
      'isOnline': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: const AgentCustomHeader(
        sectionTitle: 'Messages',
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                const Icon(Icons.search, color: Colors.grey, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Rechercher des conversations...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Liste des conversations
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _conversations.length,
              itemBuilder: (context, index) {
                final conversation = _conversations[index];
                return _buildConversationTile(conversation);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(Map<String, dynamic> conversation) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AgentChatScreen(
              conversationId: conversation['id'],
              userName: conversation['name'],
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar avec statut en ligne
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(conversation['avatar']),
                ),
                if (conversation['isOnline'])
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            
            // Informations de la conversation
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        conversation['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        conversation['time'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conversation['lastMessage'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Badge de messages non lus
            if (conversation['unreadCount'] > 0)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD400),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    conversation['unreadCount'].toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
