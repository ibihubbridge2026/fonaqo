import 'package:flutter/material.dart';

/// Bandeau affiché lorsqu'un pass boost agent est actif.
class AgentBoostStatusBanner extends StatelessWidget {
  const AgentBoostStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFA5D6A7)),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Color(0xFF2E7D32),
              size: 22,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Statut : Profil Boosté Actif (Priorité 10 min sur les missions)',
                style: TextStyle(
                  color: Color(0xFF1B5E20),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
