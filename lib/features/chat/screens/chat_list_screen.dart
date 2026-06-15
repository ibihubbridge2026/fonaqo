import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/skeleton_loading.dart';
import '../../../widgets/custom_app_bar.dart';
import '../models/chat_room.dart';
import '../providers/chat_provider.dart';
import 'package:go_router/go_router.dart';

/// Liste des conversations — shimmer au chargement initial, transition fluide.
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late final ChatProvider _chatProvider;

  @override
  void initState() {
    super.initState();
    _chatProvider = ChatProvider();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatProvider.loadConversations(context);
    });
  }

  @override
  void dispose() {
    _chatProvider.dispose();
    super.dispose();
  }

  void _openConversation(ChatRoom room) {
    final other = room.getOtherParticipant(
      context.read<AuthProvider>().currentUser?.id ?? '',
    );
    context.push(AppRoutes.chatDetail, extra: {
        'conversationId': room.id,
        'chatId': room.id,
        'userName': other?.userName ?? room.name,
        'missionId': room.missionId,
      },
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ChatProvider>.value(
      value: _chatProvider,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F8F8),
        appBar: const CustomAppBar.detailStack(
          title: 'Messages',
          detailTitleWidget: Text(
            'Messages',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        ),
        body: Consumer<ChatProvider>(
          builder: (context, chat, _) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _buildBody(context, chat),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ChatProvider chat) {
    if (chat.isLoadingConversations && chat.conversations.isEmpty) {
      return KeyedSubtree(
        key: const ValueKey('chat_shimmer'),
        child: SkeletonLoading.conversationList(),
      );
    }

    if (chat.conversations.isEmpty) {
      return KeyedSubtree(
        key: const ValueKey('chat_empty'),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline,
                  size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Aucune conversation',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Vos échanges avec les agents apparaîtront ici.',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return KeyedSubtree(
      key: const ValueKey('chat_list'),
      child: RefreshIndicator(
        color: const Color(0xFFFFD400),
        onRefresh: () => chat.loadConversations(context),
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: chat.conversations.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final room = chat.conversations[index];
            final userId =
                context.read<AuthProvider>().currentUser?.id ?? '';
            final other = room.getOtherParticipant(userId);
            final name = other?.userName ?? room.name;
            final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
            final preview = room.lastMessage?.content ?? 'Pas de message';
            final time = _formatTime(room.updatedAt);

            return Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              elevation: 0,
              child: InkWell(
                onTap: () => _openConversation(room),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor:
                            const Color(0xFFFFD400).withValues(alpha: 0.25),
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF715D00),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                if (time.isNotEmpty)
                                  Text(
                                    time,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (room.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD400),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${room.unreadCount}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
