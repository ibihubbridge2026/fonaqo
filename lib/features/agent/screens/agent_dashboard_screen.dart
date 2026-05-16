import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/mission_card.dart';
import '../widgets/agent_stat_card.dart';
import '../widgets/shimmer_loading_card.dart';
import '../providers/agent_provider.dart';
import 'agent_boost_screen.dart';
import 'agent_chat_screen.dart';
import 'agent_mission_history_screen.dart';
import 'agent_missions_explorer_screen.dart';
import 'agent_notifications_screen.dart';
import 'agent_settings_screen.dart';
import 'agent_wallet_screen.dart';

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

                // ================= BARRE DE RECHERCHE =================
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.grey, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Rechercher des missions...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.tune,
                            color: Colors.black, size: 16),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

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
                            color: Colors.black.withOpacity(.08),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                            spreadRadius: 1,
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

                const SizedBox(height: 20),

                // ================= SECTION IMAGE LIGHT =================
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7CC),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Boostez vos missions',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Augmentez votre visibilité',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AgentBoostScreen(),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Découvrir',
                                    style: TextStyle(
                                      color: Color(0xFFFFD400),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD400).withOpacity(0.3),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          child: const Icon(
                            Icons.rocket_launch,
                            size: 40,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
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

                // 2. BALANCE CARD
                _buildBalanceCard(),

                const SizedBox(height: 20),

                // 3. QUICK ACTIONS
                _buildQuickActions(),

                const SizedBox(height: 30),

                // 4. MISSIONS
                _buildCurrentMissions(),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AgentSettingsScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFFFFD400),
        child: const Icon(Icons.settings, color: Colors.black),
      ),
    );
  }

  // ================= WIDGET BUILDERS =================

  // 2. BALANCE CARD
  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFEFEF6), Color(0xFFFFF5C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFFFE78B)),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFFFCC00).withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 15))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Solde disponible",
                  style: GoogleFonts.poppins(
                      color: Colors.grey[700], fontSize: 14)),
              const SizedBox(height: 5),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontSize: 32,
                      fontWeight: FontWeight.w800),
                  children: [
                    const TextSpan(text: "245 600 "),
                    TextSpan(
                        text: "FCFA",
                        style: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AgentWalletScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFCC00),
              foregroundColor: Colors.black,
              elevation: 5,
              shadowColor: const Color(0xFFFFCC00).withOpacity(0.5),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
            child: Text("Retirer",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  // 3. QUICK ACTIONS
  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _actionItem("Recharger", Icons.account_balance_wallet_outlined,
            const Color(0xFFFFF5D8), const Color(0xFFFFB800)),
        _actionItem("Transactions", Icons.swap_horiz_rounded,
            const Color(0xFFEDF4FF), const Color(0xFF3B82F6)),
        _actionItem("Boost", Icons.rocket_launch_outlined,
            const Color(0xFFECFFF1), const Color(0xFF22C55E)),
        _actionItem("PDF", Icons.description_outlined, const Color(0xFFF5EEFF),
            const Color(0xFF8B5CF6)),
      ],
    );
  }

  Widget _actionItem(String label, IconData icon, Color bg, Color color) {
    return GestureDetector(
      onTap: () {
        // Navigation selon le label
        switch (label) {
          case "Recharger":
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AgentWalletScreen(),
              ),
            );
            break;
          case "Transactions":
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AgentWalletScreen(),
              ),
            );
            break;
          case "Boost":
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AgentBoostScreen(),
              ),
            );
            break;
          case "PDF":
            // Action pour générer PDF (déjà implémenté dans wallet)
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AgentWalletScreen(),
              ),
            );
            break;
        }
      },
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 5))
              ],
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800])),
        ],
      ),
    );
  }

  // 4. MISSIONS
  Widget _buildCurrentMissions() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Missions en cours",
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w800)),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AgentMissionHistoryScreen(),
                  ),
                );
              },
              child: Text("Voir tout",
                  style: GoogleFonts.poppins(
                      color: const Color(0xFFFFB800),
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 15),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AgentMissionsExplorerScreen(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.network("https://i.pravatar.cc/100?img=15",
                          width: 50, height: 50),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Attente à la BOA",
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("Place de l'indépendance",
                              style: GoogleFonts.poppins(
                                  color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: const Color(0xFFECFFF1),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text("En cours",
                          style: GoogleFonts.poppins(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 11)),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                _buildTimelineStep("Mission acceptée", "08:15", true),
                _buildTimelineStep("En route", "08:20", true),
                _buildTimelineStep("Arrivé sur place", "08:35", true),
                _buildTimelineStep("En attente", "2 pers. avant vous", false),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineStep(String title, String time, bool completed) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: completed ? Colors.green : Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: completed ? Colors.black : Colors.grey,
              fontWeight: completed ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
        Text(
          time,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
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
          width: 60,
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            time,
            style: const TextStyle(
              color: kPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: kText,
            ),
          ),
        ),
      ],
    );
  }
}
