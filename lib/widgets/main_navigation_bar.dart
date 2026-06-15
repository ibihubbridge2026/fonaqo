import 'package:flutter/material.dart';

import 'package:fonaco/l10n/app_localizations.dart';

/// Barre de navigation inférieure du shell principal.
///
/// [currentIndex]: index de l'onglet actif (0 = accueil, suivi missions / Agents / profil).
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
    final l10n = AppLocalizations.of(context)!;
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
            child: _NavItem(
              index: 0,
              currentIndex: currentIndex,
              icon: Icons.home_filled,
              label: l10n.navHome,
              onTap: onTap,
            ),
          ),
          Expanded(
            child: _NavItem(
              index: 1,
              currentIndex: currentIndex,
              icon: Icons.assignment_rounded,
              label: l10n.navMissions,
              onTap: onTap,
            ),
          ),
          Expanded(
            child: _NavItem(
              index: 2,
              currentIndex: currentIndex,
              icon: Icons.group_work,
              label: l10n.navAgents,
              onTap: onTap,
            ),
          ),
          Expanded(
            child: _NavItem(
              index: 3,
              currentIndex: currentIndex,
              icon: Icons.storefront_rounded,
              label: l10n.navLeBonCoin,
              onTap: onTap,
            ),
          ),
          Expanded(
            child: _NavItem(
              index: 4,
              currentIndex: currentIndex,
              icon: Icons.settings_outlined,
              label: l10n.navSettings,
              onTap: onTap,
            ),
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
