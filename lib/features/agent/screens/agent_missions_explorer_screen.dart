import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/agent_provider.dart';
import '../widgets/mission_card.dart';

class AgentMissionsExplorerScreen extends StatefulWidget {
  const AgentMissionsExplorerScreen({super.key});

  @override
  State<AgentMissionsExplorerScreen> createState() =>
      _AgentMissionsExplorerScreenState();
}

class _AgentMissionsExplorerScreenState
    extends State<AgentMissionsExplorerScreen> {
  int _selectedFilter = 0;

  final List<String> filters = [
    'Toutes',
    'Proches',
    'Urgentes',
    'Rentables',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Consumer<AgentProvider>(
        builder: (context, agentProvider, child) {
          // Si agent hors ligne
          if (!agentProvider.isOnline) {
            return Stack(
              children: [
                _buildContent(context),
                _buildOfflineOverlay(),
              ],
            );
          }

          return _buildContent(context);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      children: [
        // SEARCH BAR
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher une mission...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                border: InputBorder.none,
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey.shade600,
                ),
                suffixIcon: Icon(
                  Icons.tune,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ),
        ),

        // FILTERS
        SizedBox(
          height: 42,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedFilter == index;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFilter = index;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFFD400) : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFFFD400)
                          : Colors.grey.shade300,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    filters[index],
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.grey.shade700,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 18),

        // CARTE INTERACTIVE
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  // Carte de base avec style Google Maps
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.blue.shade50,
                          Colors.green.shade50,
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map,
                            size: 60,
                            color: Colors.blueGrey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Carte des missions',
                            style: TextStyle(
                              color: Colors.blueGrey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '3 missions à proximité',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Points de missions simulés
                  Positioned(
                    top: 40,
                    left: 60,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 80,
                    right: 80,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 60,
                    left: 100,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                  // Bouton de localisation
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.my_location, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Carte',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // MISSIONS LIST
        Expanded(
          child: Consumer<AgentProvider>(
            builder: (context, agentProvider, child) {
              if (agentProvider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFFFD400),
                  ),
                );
              }

              final missions = agentProvider.availableMissions;

              if (missions.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.work_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Aucune mission disponible',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Activez votre statut en ligne pour voir les missions',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: missions.length,
                itemBuilder: (context, index) {
                  final mission = missions[index];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: MissionCard(
                      title: mission.title ?? 'Mission',
                      location: mission.address ?? 'Adresse non disponible',
                      client: mission.clientName ?? 'Client inconnu',
                      amount:
                          '${mission.price?.toStringAsFixed(0) ?? '0'} FCFA',
                      distance: '500 m',
                      urgent: mission.isUrgent ?? false,
                      onTap: () {
                        // TODO: Navigation détail mission
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOfflineOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(40),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.offline_bolt,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Vous êtes hors ligne',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Passez en ligne pour voir les missions',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Consumer<AgentProvider>(
                  builder: (context, agentProvider, child) {
                    return ElevatedButton(
                      onPressed: () {
                        // Passer en ligne
                        agentProvider.toggleOnlineStatus();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD400),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Passer en ligne',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
