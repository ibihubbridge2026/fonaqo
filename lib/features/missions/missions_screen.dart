import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';

class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF0),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("Mes Missions", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),

          // Barre de catégories + Bouton Ajouter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.createMission),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("CRÉER"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD400),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
                const SizedBox(width: 10),
                _buildCategoryChip("En cours", true),
                _buildCategoryChip("Terminées", false),
                _buildCategoryChip("Annulées", false),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // Liste des missions (Simulation des cartes créées)
          _buildMissionCard(context, "Mairie d'Abidjan", "File d'attente", "En cours", "12 min"),
          _buildMissionCard(context, "Poste de Cocody", "Service libre", "En attente", "2h"),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildMissionCard(BuildContext context, String title, String type, String status, String time) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.missionDetail), // Vers le détail
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFFD400).withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.assignment_outlined, color: Color(0xFFFFD400)),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("$type • $time", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(10)),
              child: Text(status, style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold, fontSize: 10)),
            )
          ],
        ),
      ),
    );
  }
}