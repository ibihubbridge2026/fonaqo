import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AgentHomeScreen extends StatefulWidget {
  const AgentHomeScreen({super.key});

  @override
  State<AgentHomeScreen> createState() => _AgentHomeScreenState();
}

class _AgentHomeScreenState extends State<AgentHomeScreen> {
  bool isAvailable = true;
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.8, -0.8),
            radius: 1.2,
            colors: [Color(0xFFFFF4C4), Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 25),
                _buildBalanceCard(),
                const SizedBox(height: 25),
                _buildQuickActions(),
                const SizedBox(height: 30),
                _buildCurrentMissions(),
                const SizedBox(height: 30),
                _buildStats(),
                const SizedBox(height: 30),
                _buildDisputeCard(),
                const SizedBox(height: 100), // Espace pour la navbar
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavbar(),
    );
  }

  // 1. HEADER
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Bonjour", 
              style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 15)),
            Text("Jean Agent 👋", 
              style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w800, color: const Color(0xFF111827))),
            const SizedBox(height: 8),
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => isAvailable = !isAvailable),
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
                      alignment: isAvailable ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(isAvailable ? "Disponible" : "Hors-ligne", 
                  style: GoogleFonts.poppins(color: isAvailable ? Colors.green : Colors.grey, fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            )
          ],
        ),
        Row(
          children: [
            _buildIconButton(Icons.comment_outlined),
            const SizedBox(width: 12),
            Stack(
              children: [
                _buildIconButton(Icons.notifications_none_outlined),
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2)))),
                )
              ],
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFFFCC00), width: 2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Image.network("https://i.pravatar.cc/100?img=12", width: 45, height: 45),
              ),
            )
          ],
        )
      ],
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Icon(icon, size: 22),
    );
  }

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
        boxShadow: [BoxShadow(color: const Color(0xFFFFCC00).withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 15))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Solde disponible", style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 14)),
              const SizedBox(height: 5),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.poppins(color: Colors.black, fontSize: 32, fontWeight: FontWeight.w800),
                  children: [
                    const TextSpan(text: "245 600 "),
                    TextSpan(text: "FCFA", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFCC00),
              foregroundColor: Colors.black,
              elevation: 5,
              shadowColor: const Color(0xFFFFCC00).withOpacity(0.5),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: Text("Retirer", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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
        _actionItem("Recharger", Icons.account_balance_wallet_outlined, const Color(0xFFFFF5D8), const Color(0xFFFFB800)),
        _actionItem("Transactions", Icons.swap_horiz_rounded, const Color(0xFFEDF4FF), const Color(0xFF3B82F6)),
        _actionItem("Boost", Icons.rocket_launch_outlined, const Color(0xFFECFFF1), const Color(0xFF22C55E)),
        _actionItem("PDF", Icons.description_outlined, const Color(0xFFF5EEFF), const Color(0xFF8B5CF6)),
      ],
    );
  }

  Widget _actionItem(String label, IconData icon, Color bg, Color color) {
    return Column(
      children: [
        Container(
          width: 65,
          height: 65,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[800])),
      ],
    );
  }

  // 4. MISSIONS
  Widget _buildCurrentMissions() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Missions en cours", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800)),
            Text("Voir tout", style: GoogleFonts.poppins(color: const Color(0xFFFFB800), fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network("https://i.pravatar.cc/100?img=15", width: 50, height: 50),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Attente à la BOA", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text("Place de l'indépendance", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFECFFF1), borderRadius: BorderRadius.circular(20)),
                    child: Text("En cours", style: GoogleFonts.poppins(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
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
        )
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
                border: Border.all(color: isDone ? Colors.green : Colors.grey[300]!, width: 3),
              ),
            ),
            Container(width: 2, height: 20, color: Colors.grey[200]),
          ],
        ),
        const SizedBox(width: 15),
        Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: isDone ? FontWeight.w600 : FontWeight.w400)),
        const Spacer(),
        Text(time, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  // 5. STATS
  Widget _buildStats() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.4,
      children: [
        _statItem("02", "Missions", Icons.assignment_outlined, Colors.blue),
        _statItem("45K", "Gains", Icons.trending_up, Colors.green),
        _statItem("4.8", "Note", Icons.star_outline, Colors.orange),
        _statItem("98%", "Réussite", Icons.bolt_outlined, Colors.purple),
      ],
    );
  }

  Widget _statItem(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(value, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800)),
          Text(label, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  // 6. DISPUTE
  Widget _buildDisputeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFF5F5), Color(0xFFFFF0F0)]),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFFFD0D0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.shield_outlined, color: Colors.red, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Ouvrir un litige", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                Text("Besoin d'aide ?", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700])),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Ouvrir", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // 7. NAVBAR
  Widget _buildBottomNavbar() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 10))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_filled, "Accueil", 0),
          _navItem(Icons.assignment_outlined, "Missions", 1),
          _navItem(Icons.account_balance_wallet_outlined, "Wallet", 2),
          _navItem(Icons.person_outline, "Profil", 3),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    bool isSel = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSel ? const Color(0xFFFFB800) : Colors.grey, size: 26),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.poppins(fontSize: 10, color: isSel ? const Color(0xFFFFB800) : Colors.grey, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}