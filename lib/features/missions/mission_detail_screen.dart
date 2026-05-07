import 'package:flutter/material.dart';
import '../../../widgets/custom_app_bar.dart';

class MissionDetailScreen extends StatelessWidget {
  const MissionDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF0),
      appBar: CustomAppBar.detailStack(detailTitleWidget: Text("Détails de la mission")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            
            const SizedBox(height: 40),
            
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text("APPELER L'AGENT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
            )
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