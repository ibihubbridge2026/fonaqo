import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/agent_theme.dart';
import '../providers/agent_provider.dart';
import '../../../core/services/app_mode_service.dart';

/// Conteneur principal pour l'interface Agent avec sa propre barre de navigation
class AgentMainShell extends StatefulWidget {
  const AgentMainShell({super.key});

  @override
  State<AgentMainShell> createState() => _AgentMainShellState();
}

class _AgentMainShellState extends State<AgentMainShell> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  // Pages de l'interface Agent
  final List<Widget> _pages = [
    const AgentDashboardScreen(),
    const AgentMissionsScreen(),
    const AgentWalletScreen(),
    const AgentProfileScreen(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<bool> _onBackPressed() async {
    if (_currentIndex != 0) {
      // Revenir au dashboard si on n'est pas déjà dessus
      _onTabTapped(0);
      return false; // Empêcher le retour
    }

    // Si on est sur le dashboard, demander confirmation pour quitter le mode Agent
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter le mode Agent'),
        content: const Text('Voulez-vous revenir au mode Client ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Oui'),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      final appModeService = AppModeService();
      final success = await appModeService.switchToClient();
      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed('/main');
      }
    }

    return false; // Empêcher le retour par défaut
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AgentTheme.lightTheme,
      child: WillPopScope(
        onWillPop: _onBackPressed,
        child: Scaffold(
          backgroundColor: AgentTheme.backgroundColor,
          appBar: AppBar(
            title: Consumer<AgentProvider>(
              builder: (context, agentProvider, child) {
                return Row(
                  children: [
                    // Logo FONACO
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bolt,
                        color: AgentTheme.primaryYellow,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'FONACO',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const Spacer(),
                    // Statut online
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: agentProvider.isOnline
                            ? AgentTheme.onlineColor
                            : AgentTheme.offlineColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            agentProvider.isOnline
                                ? Icons.circle
                                : Icons.circle_outlined,
                            color: Colors.white,
                            size: 8,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            agentProvider.isOnline ? 'En ligne' : 'Hors ligne',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            actions: [
              // Bouton pour basculer vers le mode Client
              IconButton(
                icon: const Icon(Icons.switch_account),
                onPressed: () async {
                  final appModeService = AppModeService();
                  final success = await appModeService.switchToClient();
                  if (success && mounted) {
                    Navigator.of(context).pushReplacementNamed('/main');
                  }
                },
              ),
            ],
          ),
          body: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: _pages,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: AgentTheme.surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              type: BottomNavigationBarType.fixed,
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.dashboard_outlined),
                  activeIcon: const Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.work_outline),
                  activeIcon: const Icon(Icons.work),
                  label: 'Missions',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  activeIcon: const Icon(Icons.account_balance_wallet),
                  label: 'Portefeuille',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person_outline),
                  activeIcon: const Icon(Icons.person),
                  label: 'Profil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Écrans temporaires pour la structure (seront remplacés par les vrais écrans)
class AgentDashboardScreen extends StatelessWidget {
  const AgentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Dashboard Agent\n(En développement)',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AgentTheme.secondaryTextColor,
        ),
      ),
    );
  }
}

class AgentMissionsScreen extends StatelessWidget {
  const AgentMissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Missions Agent\n(En développement)',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AgentTheme.secondaryTextColor,
        ),
      ),
    );
  }
}

class AgentWalletScreen extends StatelessWidget {
  const AgentWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Portefeuille Agent\n(En développement)',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AgentTheme.secondaryTextColor,
        ),
      ),
    );
  }
}

class AgentProfileScreen extends StatelessWidget {
  const AgentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Profil Agent\n(En développement)',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AgentTheme.secondaryTextColor,
        ),
      ),
    );
  }
}
