import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../core/providers/auth_provider.dart';
import '../core/providers/mission_provider.dart';
import '../core/providers/notification_provider.dart';
import '../core/providers/wallet_provider.dart';
import '../core/services/connectivity_sync_service.dart';
import '../features/client/home/home_screen.dart';
import '../features/client/missions/missions_screen.dart';
import '../features/client/profile/profile_screen.dart';
import '../features/client/agents_screen.dart';
import '../features/client/leboncoin/screens/le_bon_coin_screen.dart';
import '../features/agent/presentation/kyc/kyc_lock_screen.dart';
import '../features/agent/presentation/dashboard/screens/agent_dashboard_screen.dart';
import '../features/agent/screens/agent_missions_screen.dart';
import '../features/agent/screens/agent_mission_history_screen.dart';
import '../features/agent/screens/agent_wallet_screen.dart';
import '../features/agent/presentation/profile/screens/agent_profile_screen.dart';
import '../features/agent/screens/agent_notifications_screen.dart';
import '../features/agent/widgets/agent_bottom_nav.dart';
import '../core/routes/app_routes.dart';
import 'custom_app_bar.dart';
import 'main_navigation_bar.dart';
import 'package:go_router/go_router.dart';

/// Accès aux méthodes du shell principal (changement d’onglet).
class MainShellScope extends InheritedWidget {
  final int currentIndex;
  final ValueChanged<int> setIndex;
  final VoidCallback openCreateMission;
  final VoidCallback closeCreateMission;

  const MainShellScope({
    super.key,
    required this.currentIndex,
    required this.setIndex,
    required this.openCreateMission,
    required this.closeCreateMission,
    required super.child,
  });

  static MainShellScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MainShellScope>();
  }

  @override
  bool updateShouldNotify(MainShellScope oldWidget) =>
      currentIndex != oldWidget.currentIndex;
}

/// Conteneur principal après authentification : app bar dynamique + 4 destinations + navigation basse.
class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;
  final ValueNotifier<bool> _showCreateMission = ValueNotifier<bool>(false);
  bool _locationPermissionGranted = false;
  bool _showLocationBanner = false;

  late final List<Widget> _pages = [
    const HomeScreen(),
    MissionsScreen(showCreateMissionListenable: _showCreateMission),
    const AgentsScreen(),
    const LeBonCoinScreen(),
    const ProfileScreen(),
  ];

  /// Pages agent : Accueil, Missions, Historique, Wallet, Profil
  late final List<Widget> _agentPages = [
    const AgentDashboardScreen(),
    const AgentMissionsScreen(),
    const AgentMissionHistoryScreen(embeddedInShell: true),
    const AgentWalletScreen(),
    const AgentProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WalletProvider>(context, listen: false).fetchBalance();
      Provider.of<NotificationProvider>(context, listen: false)
          .reconnectAfterAuth();
      _startConnectivitySync();
    });
  }

  void _startConnectivitySync() {
    ConnectivitySyncService.instance.start(
      onReconnect: () async {
        if (!mounted) return;
        final auth = context.read<AuthProvider>();
        if (!auth.isAuthenticated) return;

        await Future.wait([
          context.read<MissionProvider>().fetchMissions(),
          context.read<WalletProvider>().fetchBalance(),
        ], eagerError: false);
      },
    );
  }

  @override
  void dispose() {
    ConnectivitySyncService.instance.stop();
    _showCreateMission.dispose();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Vérifier si le service de localisation est activé
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _showLocationBanner = true;
      });
      return;
    }

    // Demander la permission de localisation
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _showLocationBanner = true;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _showLocationBanner = true;
      });
      return;
    }

    setState(() {
      _locationPermissionGranted = true;
      _showLocationBanner = false;
    });
  }

  PreferredSizeWidget _agentAppBar() {
    return CustomAppBar.mainShellHome(
      profileTabIndex: 4,
      onNotificationsPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AgentNotificationsScreen(),
          ),
        );
      },
      onSupportPressed: () {
        context.push(AppRoutes.aiAssistant);
      },
    );
  }

  PreferredSizeWidget _appBarForIndex() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAgent = authProvider.isAgent;

    if (isAgent) {
      return _agentAppBar();
    }

    return const CustomAppBar.mainShellHome();
  }

  @override
  Widget build(BuildContext context) {
    // Vérifier si l'utilisateur est un agent
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAgent = authProvider.isAgent;
    final isKycLocked = authProvider.currentUser?.isKycLocked ?? false;

    if (isAgent && isKycLocked) {
      return const KycLockScreen();
    }

    return MainShellScope(
      currentIndex: _currentIndex,
      setIndex: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      openCreateMission: () => _showCreateMission.value = true,
      closeCreateMission: () => _showCreateMission.value = false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: isAgent ? _agentAppBar() : const CustomAppBar.mainShellHome(),
        body: Column(
          children: [
            // Bannière discrète si GPS refusé
            if (_showLocationBanner)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_off_outlined,
                      color: Colors.orange.shade700,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'La position est désactivée. Vous devrez saisir les adresses manuellement.',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showLocationBanner = false;
                        });
                      },
                      icon: Icon(
                        Icons.close,
                        color: Colors.orange.shade700,
                        size: 16,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                    ),
                  ],
                ),
              ),
            // Contenu principal - pages différentes selon le rôle
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: isAgent ? _agentPages : _pages,
              ),
            ),
          ],
        ),
        bottomNavigationBar: isAgent
            ? AgentBottomNav(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              )
            : MainNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
      ),
    );
  }
}
