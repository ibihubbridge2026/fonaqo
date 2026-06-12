import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/mission_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/wallet_provider.dart';
import 'cache_service.dart';

/// Précharge les données vitales avant d'afficher le dashboard.
class AppBootstrapService {
  static Future<void> preloadSessionData(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;

    final wallet = context.read<WalletProvider>();
    final missions = context.read<MissionProvider>();
    final notifications = context.read<NotificationProvider>();
    final favorites = context.read<FavoritesProvider>();

    final userId = auth.currentUser?.id;
    await CacheService().invalidateDashboardCache();
    final tasks = <Future<void>>[
      wallet.fetchBalance(),
      missions.fetchMissions(),
      notifications.reconnectAfterAuth(),
    ];
    if (userId != null) {
      tasks.add(favorites.init(userId));
    }

    await Future.wait(tasks, eagerError: false);
  }
}

/// Overlay de chargement pendant le bootstrap post-connexion.
class SessionBootstrapOverlay extends StatelessWidget {
  const SessionBootstrapOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFFFFD400),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Préparation de votre espace',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF121212),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Chargement du profil, du portefeuille et de vos missions…',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
