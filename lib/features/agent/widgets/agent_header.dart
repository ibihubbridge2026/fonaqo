import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F7FB),
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Section gauche: Salutation et nom
            Expanded(
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final user = authProvider.currentUser;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Bonjour",
                        style: GoogleFonts.poppins(
                            color: Colors.grey[600], fontSize: 13),
                      ),
                      Flexible(
                        child: Text(
                          "${user?.firstName ?? 'Jean'} ${user?.lastName ?? 'Agent'}",
                          style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF111827)),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Section droite: Actions
            Row(
              children: [
                // Switch disponibilité
                _buildAvailabilitySwitch(),
                const SizedBox(width: 12),

                // Bouton messages
                _buildIconButton(Icons.comment_outlined),
                const SizedBox(width: 12),

                // Bouton notifications avec badge
                AgentNotificationBadge(
                  count: 3,
                  child: _buildIconButton(Icons.notifications_none_outlined),
                ),
                const SizedBox(width: 12),

                // Avatar
                Container(
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: const Color(0xFFFFCC00), width: 2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Image.network("https://i.pravatar.cc/100?img=12",
                        width: 45, height: 45),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilitySwitch() {
    return Consumer2<AuthProvider, AgentProvider>(
      builder: (context, authProvider, agentProvider, child) {
        bool isAvailable = agentProvider.isOnline;

        return Column(
          children: [
            GestureDetector(
              onTap: () {
                // Implémentation du toggle de disponibilité
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
