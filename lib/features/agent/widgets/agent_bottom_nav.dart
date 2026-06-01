import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AgentBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AgentBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _navItem(Icons.home_filled, "Accueil", 0),
          ),
          Expanded(
            child: _navItem(Icons.assignment_outlined, "Missions", 1),
          ),
          Expanded(
            child: _navItem(Icons.account_balance_wallet_outlined, "Wallet", 2),
          ),
          Expanded(
            child: _navItem(Icons.person_outline, "Profil", 3),
          ),
          Expanded(
            child: _navItem(Icons.settings_outlined, "Paramètres", 4),
          ),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isActive = currentIndex == index;
    const activeColor = Color(0xFFFFD400);
    final inactiveColor = Colors.grey[400];

    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive ? activeColor : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.black : inactiveColor,
              size: 24,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.black : inactiveColor,
            ),
          ),
        ],
      ),
    );
  }
}
