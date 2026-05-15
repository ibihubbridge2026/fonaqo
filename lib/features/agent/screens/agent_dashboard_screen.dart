import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/mission_card.dart';
import '../widgets/agent_stat_card.dart';
import '../widgets/shimmer_loading_card.dart';
import '../providers/agent_provider.dart';

class AgentDashboardScreen extends StatefulWidget {
  const AgentDashboardScreen({super.key});

  @override
  State<AgentDashboardScreen> createState() => _AgentDashboardScreenState();
}

class _AgentDashboardScreenState extends State<AgentDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Initialiser les données au chargement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AgentProvider>().initAgentData();
    });
  }

  static const Color kPrimary = Color(0xFFFFD400);
  static const Color kBackground = Color(0xFFF8F9FB);
  static const Color kText = Color(0xFF111111);
  static const Color kSubtitle = Color(0xFF777777);
  static const Color kBorder = Color(0xFFEAEAEA);
  static const Color kSuccess = Color(0xFF22C55E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<AgentProvider>().refreshDashboardData();
        },
        color: kPrimary,
        child: SafeArea(
          child: SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(), // Important pour RefreshIndicator
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),

                // ================= WALLET CARD =================
                Consumer<AgentProvider>(
                  builder: (context, agentProvider, child) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: agentProvider.isLoading
                          ? const WalletShimmer()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Solde disponible',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: kSubtitle,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: agentProvider.isLoading
                                          ? null
                                          : () {
                                              agentProvider
                                                  .refreshDashboardData();
                                            },
                                      icon: agentProvider.isLoading
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: kPrimary,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.refresh,
                                              size: 18,
                                              color: kPrimary,
                                            ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${agentProvider.balance.toStringAsFixed(2)} XOF',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: kText,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '+2 400 XOF aujourd\'hui',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: kSuccess,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    );
                  },
                ),

                const SizedBox(height: 30),

                // ================= SECTION TITLE =================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Missions urgentes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Voir tout',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // ================= MISSIONS URGENTES =================
                Consumer<AgentProvider>(
                  builder: (context, agentProvider, child) {
                    if (agentProvider.isLoading) {
                      return const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Missions urgentes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: kText,
                            ),
                          ),
                          SizedBox(height: 16),
                          MissionCardShimmer(),
                          MissionCardShimmer(),
                        ],
                      );
                    }

                    final missions = agentProvider.availableMissions
                        .where((m) => m.isUrgent)
                        .toList();

                    if (missions.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: kBorder),
                        ),
                        child: const Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.work_outline,
                                size: 48,
                                color: kSubtitle,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Aucune mission urgente',
                                style: TextStyle(
                                  color: kSubtitle,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Missions urgentes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: kText,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...missions.map((mission) {
                          return MissionCard(
                            title: mission.title,
                            location: mission.address ?? 'Non spécifié',
                            amount: '${mission.price.toStringAsFixed(0)} FCFA',
                            client: mission.clientName ?? 'Client',
                            distance:
                                '500m', // Temporaire - à calculer avec coordonnées
                            urgent: mission.isUrgent,
                            onTap: () {
                              // Navigation vers détail mission
                            },
                          );
                        }),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 30),

                // ================= STATISTIQUES JOURNALIÈRES =================
                Consumer<AgentProvider>(
                  builder: (context, agentProvider, child) {
                    return agentProvider.isLoading
                        ? const StatsShimmer()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Aujourd\'hui',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: kText,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: AgentStatCard(
                                      title:
                                          '${agentProvider.stats['missions_completed_today'] ?? 0}',
                                      subtitle: 'Missions',
                                      icon: Icons.work_outline,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: AgentStatCard(
                                      title:
                                          '${agentProvider.stats['earnings_today'] ?? 0} XOF',
                                      subtitle: 'Gains',
                                      icon: Icons.trending_up,
                                      iconColor: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: AgentStatCard(
                                      title:
                                          '${agentProvider.stats['rating_today'] ?? 0.0}',
                                      subtitle: 'Note',
                                      icon: Icons.star,
                                      iconColor: Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: AgentStatCard(
                                      title:
                                          '${agentProvider.stats['active_time_today'] ?? 0}h',
                                      subtitle: 'Temps actif',
                                      icon: Icons.access_time,
                                      iconColor: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                  },
                ),

                const SizedBox(height: 18),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _timelineTile(
                        time: '10:00',
                        title: 'File d’attente - SBEE',
                      ),
                      const Divider(height: 30),
                      _timelineTile(
                        time: '12:00',
                        title: 'Livraison document - Calavi',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // ================= TIMELINE PRÉVISIONNEL =================
                const Text(
                  'Prochaines missions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: kText,
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _timelineTile(
                        time: '10:00',
                        title: 'File d\'attente - SBEE',
                      ),
                      const Divider(height: 30),
                      _timelineTile(
                        time: '12:00',
                        title: 'Livraison document - Calavi',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= TIMELINE TILE =================

  Widget _timelineTile({
    required String time,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: const BoxDecoration(
            color: kPrimary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          time,
          style: const TextStyle(
            color: kSubtitle,
          ),
        ),
      ],
    );
  }
}
