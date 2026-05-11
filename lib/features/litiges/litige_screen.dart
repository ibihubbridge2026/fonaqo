import 'package:flutter/material.dart';

import '../../widgets/custom_app_bar.dart';

/// Écran d’ouverture d’un litige depuis le dashboard.
class LitigeScreen extends StatelessWidget {
  const LitigeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: const CustomAppBar.detailStack(
        title: 'Ouvrir un litige',
        detailTitleWidget: Text(
          'Ouvrir un litige',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          const Text(
            'Expliquez le problème',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            "Choisissez la mission concernée puis décrivez la situation. Nous reviendrons vers vous rapidement.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          _Card(
            child: DropdownButtonFormField<String>(
              initialValue: "Mairie d'Abidjan",
              items: const [
                DropdownMenuItem(
                  value: "Mairie d'Abidjan",
                  child: Text("Mairie d'Abidjan • En cours"),
                ),
                DropdownMenuItem(
                  value: "Poste de Cocody",
                  child: Text("Poste de Cocody • En attente"),
                ),
              ],
              onChanged: (_) {},
              decoration: const InputDecoration(
                labelText: 'Mission',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const _Card(
            child: TextField(
              maxLines: 6,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Décrivez le problème, ajoutez des détails utiles…',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _Card(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD400).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.attach_file, color: Colors.black),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Ajouter une pièce jointe',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                TextButton(onPressed: () {}, child: const Text('Importer')),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'SOUMETTRE',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: child,
    );
  }
}
