import 'package:flutter/material.dart';

/// Barre de navigation inférieure du shell principal.
///
/// [currentIndex]: index de l'onglet actif (0 = accueil, suivi missions / tickets / profil).
///
/// [onTap]: invoquée avec le nouvel index lorsqu'un utilisateur sélectionne un onglet.
class MainNavigationBar extends StatelessWidget {
  /// Index de la page sélectionnée (0 à 3).
  final int currentIndex;

  /// Callback appelée avec la position de l’onglet choisi.
  final ValueChanged<int> onTap;

  const MainNavigationBar({
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
          _NavItem(
            index: 0,
            currentIndex: currentIndex,
            icon: Icons.home_filled,
            label: 'Home',
            onTap: onTap,
          ),
          _NavItem(
            index: 1,
            currentIndex: currentIndex,
            icon: Icons.assignment_rounded,
            label: 'Missions',
            onTap: onTap,
          ),
          _NavItem(
            index: 2,
            currentIndex: currentIndex,
            icon: Icons.confirmation_number_rounded,
            label: 'Tickets',
            onTap: onTap,
          ),
          _NavItem(
            index: 3,
            currentIndex: currentIndex,
            icon: Icons.person_rounded,
            label: 'Profil',
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  /// Index représenté par cet élément.
  final int index;

  /// Index actuellement actif dans le parent.
  final int currentIndex;

  final IconData icon;
  final String label;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentIndex == index;
    final activeColor = const Color(0xFFFFD400);
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
            style: TextStyle(
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
