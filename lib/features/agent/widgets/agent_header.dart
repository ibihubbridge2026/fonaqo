import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';

import '../../../core/providers/auth_provider.dart';
import '../providers/agent_provider.dart';
import '../../../core/services/app_mode_service.dart';

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
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title != null
          ? Text(
              title!,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            )
          : _buildDefaultHeader(context),
      backgroundColor: const Color(0xFFFFD400),
      foregroundColor: Colors.black,
      elevation: 0,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: onBackPressed ?? () => Navigator.pop(context),
            )
          : null,
      actions: actions ?? _buildDefaultActions(context),
    );
  }

  Widget _buildDefaultHeader(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        return Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: const NetworkImage('https://i.pravatar.cc/300'),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bonjour 👋',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  '${user?.firstName ?? 'Agent'} ${user?.lastName ?? ''}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildDefaultActions(BuildContext context) {
    return [
      Consumer<AgentProvider>(
        builder: (context, agentProvider, child) {
          return FutureBuilder<bool>(
            future: _toggleOnlineStatusWithFeedback(context, agentProvider),
            builder: (context, snapshot) {
              return Switch(
                value: agentProvider.isOnline,
                activeColor: Colors.green,
                inactiveThumbColor: Colors.grey,
                onChanged: (value) {
                  // La gestion est faite dans _toggleOnlineStatusWithFeedback
                  _toggleOnlineStatusWithFeedback(context, agentProvider);
                },
              );
            },
          );
        },
      ),
      IconButton(
        icon: const Icon(Icons.notifications_outlined),
        onPressed: () {
          // TODO: Implémenter les notifications
        },
      ),
      IconButton(
        icon: const Icon(Icons.switch_account),
        onPressed: () async {
          await AppModeService().switchToClient();
          if (context.mounted) {
            Navigator.pushReplacementNamed(context, '/main');
          }
        },
      ),
    ];
  }

  /// Gère le changement de statut online/offline avec feedback utilisateur
  Future<bool> _toggleOnlineStatusWithFeedback(
      BuildContext context, AgentProvider agentProvider) async {
    final originalStatus = agentProvider.isOnline;

    try {
      await agentProvider.toggleOnlineStatus();

      // Succès - afficher un message discret
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              agentProvider.isOnline
                  ? 'Vous êtes maintenant en ligne'
                  : 'Vous êtes maintenant hors ligne',
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }

      return true;
    } catch (e) {
      // Erreur - revenir à l'état original et afficher un message d'erreur
      _logger.e('Erreur changement statut online: $e');

      // Forcer la restauration du statut original
      agentProvider.setOnlineStatus(originalStatus);

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                const Text('Erreur de connexion. Vérifiez votre internet.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            action: SnackBarAction(
              label: 'Réessayer',
              textColor: Colors.white,
              onPressed: () =>
                  _toggleOnlineStatusWithFeedback(context, agentProvider),
            ),
          ),
        );
      }

      return false;
    }
  }

  static final Logger _logger = Logger();
}
