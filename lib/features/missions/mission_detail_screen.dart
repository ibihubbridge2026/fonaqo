import 'package:flutter/material.dart';
import '../../../widgets/custom_app_bar.dart';
import 'widgets/step_5_tracking_view.dart';

class MissionDetailScreen extends StatelessWidget {
  const MissionDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: const CustomAppBar.detailStack(
        detailTitleWidget: Text("Détails de la mission", style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image de contexte (avant le lieu)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.asset(
                  'assets/images/hero/img-2.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 48),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
              child: const Text("AGENT EN ROUTE", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w900, fontSize: 10)),
            ),
            const SizedBox(height: 15),
            const Text("Mairie d'Abidjan", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            const Text("File d'attente pour acte de naissance", style: TextStyle(color: Colors.grey)),
            
            const SizedBox(height: 30),
            
            // Agent Card (Détail)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              child: Row(
                children: [
                  const CircleAvatar(radius: 25, backgroundImage: NetworkImage("https://i.pravatar.cc/100?u=1")),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Moussa D.", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("Agent Certifié Fonaqo", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.phone, color: Colors.green)),
                ],
              ),
            ),

            const SizedBox(height: 30),
            const Text("Résumé du paiement", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildInfoTile("Montant bloqué", "2 500 CFA"),
            _buildInfoTile("Heure de début", "14:30"),
            
            const SizedBox(height: 24),

            // Tracking + actions
            const Text("Suivi", style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Step5TrackingView(
              onBackToMissions: () {},
              showBackButton: false,
            ),
            const SizedBox(height: 18),
            const Text("Actions", style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text("LIBÉRER L'ARGENT", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD400),
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text("FINALISER", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("APPELER L'AGENT", style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}