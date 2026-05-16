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
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 10))
        ],
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
    bool isSel = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: isSel ? const Color(0xFFFFB800) : Colors.grey, size: 26),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: isSel ? const Color(0xFFFFB800) : Colors.grey,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
