import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/notification_provider.dart';
import '../../../core/services/cache_service.dart';
import '../../chat/screens/chat_list_screen.dart';
import '../screens/agent_notifications_screen.dart';
import '../providers/agent_provider.dart';
import 'agent_notification_badge.dart';

class AgentHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;

  const AgentHeader({
    super.key,
    this.title,
    this.showBackButton = false,
    this.onBackPressed,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    // Ensure CacheService is initialized
    if (!CacheService().isInitialized) {
      CacheService().init().catchError((e) {
        // Silently fail initialization, app will work without cache
      });
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 1,
            offset: const Offset(0, 0.5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Section gauche: Accès au chat (liste des conversations)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatListScreen(),
                  ),
                );
              },
              child: _buildIconButton(Icons.chat_bubble_outline),
            ),

            // Section centre: Switch de disponibilité (centré horizontalement)
            _buildAvailabilitySwitch(),

            // Section droite: Notifications avec badge
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AgentNotificationsScreen(),
                  ),
                );
              },
              child: Consumer<NotificationProvider>(
                builder: (context, notif, _) => AgentNotificationBadge(
                  count: notif.unreadNotifications,
                  child: _buildIconButton(Icons.notifications_none_outlined),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilitySwitch() {
    return Consumer<AgentProvider>(
      builder: (context, agentProvider, child) {
        bool isAvailable = agentProvider.isOnline;

        return Column(
          children: [
            GestureDetector(
              onTap: () {
                agentProvider.toggleOnlineStatus();
              },
              child: Container(
                width: 50,
                height: 26,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isAvailable ? Colors.green : Colors.grey[400],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: isAvailable
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(isAvailable ? "Disponible" : "Hors-ligne",
                style: GoogleFonts.poppins(
                    color: isAvailable ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.w600,
                    fontSize: 10)),
          ],
        );
      },
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: Icon(icon, size: 22),
    );
  }
}
