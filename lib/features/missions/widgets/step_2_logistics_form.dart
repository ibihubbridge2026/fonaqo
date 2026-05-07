import 'package:flutter/material.dart';

class Step2LogisticsForm extends StatelessWidget {
  final String mode;
  final VoidCallback onNext;

  const Step2LogisticsForm({super.key, required this.mode, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Où et quand ?", 
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
        const SizedBox(height: 25),
        
        // CHAMP LIEU
        _buildInput(Icons.location_on, "Lieu (Mairie, Poste, etc.)"),
        const SizedBox(height: 16),

        // MODULE PROCURATION (uniquement pour Service Libre)
        if (mode == 'service') ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1C1C),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.gavel, color: Color(0xFFFFD400), size: 18),
                    SizedBox(width: 8),
                    Text("Besoin d'une procuration ?", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(child: _buildProcBtn("✍️ Signature")),
                    const SizedBox(width: 10),
                    Expanded(child: _buildProcBtn("📤 Upload PDF")),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // HEURE ET BUDGET
        Row(
          children: [
            Expanded(child: _buildInput(Icons.access_time, "Heure", isHalf: true)),
            const SizedBox(width: 16),
            Expanded(child: _buildInput(Icons.payments_outlined, "Budget", isHalf: true, value: "2500")),
          ],
        ),

        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: onNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: const Text("VALIDER LES DÉTAILS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        )
      ],
    );
  }

  Widget _buildInput(IconData icon, String hint, {bool isHalf = false, String? value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: TextField(
        controller: value != null ? TextEditingController(text: value) : null,
        decoration: InputDecoration(
          icon: Icon(icon, color: const Color(0xFFFFD400), size: 20),
          hintText: hint,
          border: InputBorder.none,
          hintStyle: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildProcBtn(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Center(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10))),
    );
  }
}