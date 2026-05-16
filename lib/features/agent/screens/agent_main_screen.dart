import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../providers/agent_provider.dart';

/// Écran principal pour l'interface Agent (temporaire pour tester la structure)
class AgentMainScreen extends StatefulWidget {
  const AgentMainScreen({super.key});

  @override
  State<AgentMainScreen> createState() => _AgentMainScreenState();
}

class _AgentMainScreenState extends State<AgentMainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interface Agent'),
        backgroundColor: const Color(0xFFFFD400),
        foregroundColor: Colors.black,
        actions: [
          Consumer<AgentProvider>(
            builder: (context, agentProvider, child) {
              return IconButton(
                icon: Icon(
                  agentProvider.isOnline ? Icons.online_prediction : Icons.offline_bolt,
                  color: agentProvider.isOnline ? Colors.green : Colors.grey,
                ),
                onPressed: () {
                  agentProvider.toggleOnlineStatus();
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
          ),
        ],
      ),
      body: Consumer<AgentProvider>(
        builder: (context, agentProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec informations de l'agent
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tableau de bord Agent',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            final user = authProvider.currentUser;
                            return Text(
                              'Bienvenue, ${user?.firstName ?? 'Agent'}',
                              style: Theme.of(context).textTheme.bodyLarge,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Carte de solde
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet, size: 40),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Solde disponible',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '${agentProvider.balance.toStringAsFixed(2)} XOF',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Statut en ligne
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          agentProvider.isOnline ? Icons.circle : Icons.circle_outlined,
                          color: agentProvider.isOnline ? Colors.green : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          agentProvider.isOnline ? 'En ligne' : 'Hors ligne',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: agentProvider.isOnline ? Colors.green : Colors.grey,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: agentProvider.isOnline,
                          onChanged: (value) {
                            agentProvider.setOnlineStatus(value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Missions disponibles
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.work, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'Missions disponibles',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${agentProvider.availableMissions.length}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: const Color(0xFFFFD400),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (agentProvider.availableMissions.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'Aucune mission disponible pour le moment',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        else
                          ...agentProvider.availableMissions.take(3).map((mission) {
                            return ListTile(
                              title: Text(mission.title),
                              subtitle: Text('${mission.price.toStringAsFixed(0)} XOF'),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                // Navigation vers détail mission (à implémenter)
                              },
                            );
                          }),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Actions rapides
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Actions rapides',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Rafraîchir les données
                                  _refreshAgentData();
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Rafraîchir'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Voir le profil (à implémenter)
                                },
                                icon: const Icon(Icons.person),
                                label: const Text('Profil'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _refreshAgentData() {
    // Cette méthode sera implémentée pour rafraîchir les données de l'agent
    final agentProvider = Provider.of<AgentProvider>(context, listen: false);
    
    // Simulation de rafraîchissement (à remplacer par des vrais appels API)
    agentProvider.updateBalance(15000.0);
    agentProvider.updateAvailableMissions([]);
  }
}
