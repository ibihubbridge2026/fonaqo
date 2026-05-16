import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/providers/auth_provider.dart';
import '../providers/agent_provider.dart';
import '../screens/agent_chat_list_screen.dart';
import '../screens/agent_notifications_list_screen.dart';

/// Header personnalisé pour l'agent basé sur le design du client avec toggle disponibilité
class AgentCustomHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? sectionTitle;
  final VoidCallback? onNotificationsPressed;
  final VoidCallback? onChatPressed;

  const AgentCustomHeader({
    super.key,
    this.sectionTitle,
    this.onNotificationsPressed,
    this.onChatPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  static const Color _accent = Color(0xFFFFD400);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: _buildLeading(context),
      title: _buildTitle(context),
      actions: _buildActions(context),
    );
  }

  Widget _buildLeading(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Center(
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            final user = auth.currentUser;
            final avatarUrl = user?.avatarUrl;
            final imageUrl = avatarUrl != null
                ? "${avatarUrl}?t=${DateTime.now().millisecondsSinceEpoch}"
                : null;

            return CircleAvatar(
              key: ValueKey(avatarUrl),
              radius: 20,
              backgroundImage: imageUrl != null
                  ? NetworkImage(imageUrl) as ImageProvider
                  : const AssetImage('assets/images/avatar/user.png'),
              backgroundColor: Colors.grey[200],
              child: avatarUrl == null
                  ? const Icon(Icons.person, color: Colors.black54, size: 20)
                  : null,
            );
          },
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    if (sectionTitle != null) {
      return Text(
        sectionTitle!,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      );
    }

    // Page d'accueil agent - affiche "FONAQO Agent"
    return const Text(
      'Agent',
      style: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w900,
        fontSize: 18,
        letterSpacing: 0.5,
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    return [
      // Toggle disponibilité
      Consumer2<AuthProvider, AgentProvider>(
        builder: (context, authProvider, agentProvider, child) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    agentProvider.toggleOnlineStatus();
                  },
                  child: Container(
                    width: 40,
                    height: 22,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: agentProvider.isOnline
                          ? Colors.green
                          : Colors.grey[400],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      alignment: agentProvider.isOnline
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  agentProvider.isOnline ? "En ligne" : "Hors ligne",
                  style: TextStyle(
                    color: agentProvider.isOnline ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.w600,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          );
        },
      ),
      const SizedBox(width: 8),
      IconButton(
        icon: const Icon(
          Icons.notifications_none_rounded,
          color: Colors.black54,
        ),
        onPressed: onNotificationsPressed ??
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AgentNotificationsListScreen(),
                ),
              );
            },
      ),
      IconButton(
        icon: const Icon(
          Icons.chat_outlined,
          color: Colors.black54,
        ),
        onPressed: onChatPressed ??
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AgentChatListScreen(),
                ),
              );
            },
      ),
    ];
  }
}
