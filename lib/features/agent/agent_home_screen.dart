import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import './providers/agent_provider.dart';
import '../../core/models/mission_model.dart';
import './screens/agent_mission_detail_screen.dart';
import './screens/agent_boost_screen.dart';
import '../../widgets/main_wrapper.dart';

class AgentHomeScreen extends StatefulWidget {
  const AgentHomeScreen({super.key});

  @override
  State<AgentHomeScreen> createState() => _AgentHomeScreenState();
}

class _AgentHomeScreenState extends State<AgentHomeScreen> {
  final Logger _logger = Logger();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    // Lazy loading: delay data loading until after first frame
    Future.microtask(() => _refreshData());
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });

    final agentProvider = Provider.of<AgentProvider>(context, listen: false);

    try {
      await Future.wait([
        agentProvider.fetchWalletDetails(),
        agentProvider.fetchAvailableMissions(),
        agentProvider.fetchStats(),
      ]);
    } catch (e) {
      _logger.e('Error refreshing data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: const Color(0xFFFFD400),
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                _buildBalanceCard(),
                const SizedBox(height: 20),
                _buildQuickActions(),
                const SizedBox(height: 25),
                _buildCurrentMissions(),
                const SizedBox(height: 25),
                _buildStats(),
                const SizedBox(height: 25),
                _buildMissionHistory(),
                const SizedBox(height: 25),
                _buildDisputeCard(),
                const SizedBox(height: 100), // Espace pour la navbar
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 2. BALANCE CARD
  Widget _buildBalanceCard() {
    final agentProvider = Provider.of<AgentProvider>(context, listen: false);
    final balance = agentProvider.balance;

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Solde disponible",
                  style:
                      GoogleFonts.poppins(color: Colors.black, fontSize: 14)),
              const SizedBox(height: 5),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontSize: 32,
                      fontWeight: FontWeight.w800),
                  children: [
                    TextSpan(text: "${balance.toStringAsFixed(0)} "),
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
              final mainShell = MainShellScope.maybeOf(context);
              if (mainShell != null) {
                mainShell.setIndex(2); // Navigate to Wallet screen
              }
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
            const Color(0xFFFFF5D8), const Color(0xFFFFB800), () {
          final mainShell = MainShellScope.maybeOf(context);
          if (mainShell != null) {
            mainShell.setIndex(2); // Navigate to Wallet screen
          }
        }),
        _actionItem("Transactions", Icons.swap_horiz_rounded,
            const Color(0xFFEDF4FF), const Color(0xFF3B82F6), () {
          final mainShell = MainShellScope.maybeOf(context);
          if (mainShell != null) {
            mainShell
                .setIndex(2); // Navigate to Wallet (historique transactions)
          }
        }),
        _actionItem("Boost", Icons.rocket_launch_outlined,
            const Color(0xFFECFFF1), const Color(0xFF22C55E), () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AgentBoostScreen(),
            ),
          );
        }),
        _actionItem("PDF", Icons.description_outlined, const Color(0xFFF5EEFF),
            const Color(0xFF8B5CF6), () {
          // TODO: Call API /api/v1/wallets/monthly_report/
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Génération du rapport PDF en cours...'),
              backgroundColor: Colors.black,
            ),
          );
        }),
      ],
    );
  }

  Widget _actionItem(
      String label, IconData icon, Color bg, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
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
                  color: Colors.black)),
        ],
      ),
    );
  }

  // 4. MISSIONS
  Widget _buildCurrentMissions() {
    final agentProvider = Provider.of<AgentProvider>(context, listen: false);
    final missions = agentProvider.availableMissions;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Missions disponibles",
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black)),
            GestureDetector(
              onTap: () {
                final mainShell = MainShellScope.maybeOf(context);
                if (mainShell != null) {
                  mainShell.setIndex(1); // Navigate to Missions screen
                }
              },
              child: Text("Voir tout",
                  style: GoogleFonts.poppins(
                      color: const Color(0xFFFFB800),
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 15),
        if (missions.isEmpty)
          Container(
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
            child: Center(
              child: Text(
                "Aucune mission disponible",
                style: GoogleFonts.poppins(color: Colors.black),
              ),
            ),
          )
        else
          ...missions.take(3).map((mission) => GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AgentMissionDetailScreen(mission: mission),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5))
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: mission.avatarUrl != null
                            ? Image.network(mission.avatarUrl!,
                                width: 50, height: 50, fit: BoxFit.cover)
                            : Container(
                                width: 50,
                                height: 50,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFD400),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    (mission.clientName?.isNotEmpty ?? false)
                                        ? mission.clientName![0].toUpperCase()
                                        : 'C',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(mission.title,
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black)),
                            Text(mission.address ?? 'Non spécifié',
                                style: GoogleFonts.poppins(
                                    color: Colors.black54, fontSize: 13)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: const Color(0xFFECFFF1),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text("${mission.price.toStringAsFixed(0)} FCFA",
                            style: GoogleFonts.poppins(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 11)),
                      )
                    ],
                  ),
                ),
              )),
      ],
    );
  }

  Widget _buildTimelineStep(String title, String time, bool isDone) {
    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                color: isDone ? Colors.green : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                    color: isDone ? Colors.green : Colors.grey[300]!, width: 3),
              ),
            ),
            Container(width: 2, height: 20, color: Colors.grey[200]),
          ],
        ),
        const SizedBox(width: 15),
        Text(title,
            style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: isDone ? FontWeight.w600 : FontWeight.w400,
                color: Colors.black)),
        const Spacer(),
        Text(time,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  // 5. STATS
  Widget _buildStats() {
    final agentProvider = Provider.of<AgentProvider>(context, listen: false);
    final stats = agentProvider.stats;

    final missionsCount = stats['completed_missions']?.toString() ?? '0';
    final totalEarnings = stats['total_earnings'] ?? 0.0;
    final gains = totalEarnings > 0
        ? '${(totalEarnings / 1000).toStringAsFixed(0)}K'
        : '0K';
    final rating = stats['average_rating']?.toStringAsFixed(1) ?? '0.0';
    final successRate = stats['success_rate']?.toString() ?? '95%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Mes Statistiques",
            style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black)),
        const SizedBox(height: 15),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 1.4,
          children: [
            _statItem(missionsCount, "Missions", Icons.motorcycle, Colors.blue),
            _statItem(gains, "Gains", Icons.trending_up, Colors.green),
            _statItem(rating, "Note", Icons.star_outline, Colors.orange),
            _statItem(successRate, "Missions en cours",
                Icons.check_circle_outline, Colors.purple),
          ],
        ),
      ],
    );
  }

  Widget _statItem(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black)),
          Text(label,
              style: GoogleFonts.poppins(color: Colors.black54, fontSize: 12)),
        ],
      ),
    );
  }

  // 6. MISSION HISTORY
  Widget _buildMissionHistory() {
    final agentProvider = Provider.of<AgentProvider>(context, listen: false);
    final missions = agentProvider.availableMissions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Historique des Missions",
            style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black)),
        const SizedBox(height: 15),
        if (missions.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5))
              ],
            ),
            child: Center(
              child: Text(
                "Aucune mission récente",
                style: GoogleFonts.poppins(color: Colors.black54),
              ),
            ),
          )
        else
          ...missions.take(3).map((mission) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5))
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFFF1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.check_circle,
                          color: Colors.green, size: 20),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(mission.title,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.black)),
                          Text(mission.address ?? 'Non spécifié',
                              style: GoogleFonts.poppins(
                                  color: Colors.black54, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text("${mission.price.toStringAsFixed(0)} FCFA",
                        style: GoogleFonts.poppins(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ],
                ),
              )),
      ],
    );
  }

  // 7. DISPUTE
  Widget _buildDisputeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFFFF5F5), Color(0xFFFFF0F0)]),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFFFD0D0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(15)),
            child:
                const Icon(Icons.shield_outlined, color: Colors.red, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Ouvrir un litige",
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black)),
                Text("Besoin d'aide ?",
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Ouvrir", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}
