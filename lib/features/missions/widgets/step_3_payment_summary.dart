import 'package:flutter/material.dart';

class Step3PaymentSummary extends StatelessWidget {
  final String mode;
  final VoidCallback onPaid;
  const Step3PaymentSummary({super.key, required this.mode, required this.onPaid});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Paiement sécurisé", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
        const SizedBox(height: 20),
        
        // Carte Récapitulative (Design paiement.html)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              _buildSummaryRow("Type de mission", mode == 'queue' ? "File d'attente" : "Service libre"),
              _buildSummaryRow("Frais de service", "500 CFA"),
              const Divider(height: 30),
              _buildSummaryRow("Total à payer", "2 500 CFA", isTotal: true),
            ],
          ),
        ),

        const SizedBox(height: 30),
        const Text("Choisir un moyen de paiement", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 15),

        // Liste des moyens de paiement
        _buildPaymentMethod("Orange Money", "assets/icons/orange.png", Colors.orange),
        _buildPaymentMethod("Moov Money", "assets/icons/moov.png", Colors.blue),
        _buildPaymentMethod("Wave", "assets/icons/wave.png", Colors.lightBlueAccent),
        _buildPaymentMethod("Carte Bancaire", null, Colors.black, iconData: Icons.credit_card),

        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: onPaid,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A1C1C),
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: const Text("PAYER ET ESCROW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        )
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isTotal ? Colors.black : Colors.grey, fontWeight: isTotal ? FontWeight.w900 : FontWeight.bold)),
          Text(value, style: TextStyle(fontSize: isTotal ? 18 : 14, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod(String name, String? asset, Color color, {IconData? iconData}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: asset != null ? Image.asset(asset) : Icon(iconData, color: color),
          ),
          const SizedBox(width: 15),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          const Icon(Icons.radio_button_off, color: Colors.grey, size: 20),
        ],
      ),
    );
  }
}