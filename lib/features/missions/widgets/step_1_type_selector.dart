import 'package:flutter/material.dart';

class Step1TypeSelector extends StatelessWidget {
  final Function(String) onTypeSelected;
  const Step1TypeSelector({super.key, required this.onTypeSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Que doit faire\nl'agent ?", 
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, height: 1.1)),
        const SizedBox(height: 30),
        _buildCard(context, "File d'attente", Icons.hourglass_empty, 'queue'),
        const SizedBox(height: 16),
        _buildCard(context, "Service libre", Icons.inventory_2_outlined, 'service'),
      ],
    );
  }

  Widget _buildCard(BuildContext context, String title, IconData icon, String mode) {
    return GestureDetector(
      onTap: () => onTypeSelected(mode),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFFFD400), size: 48),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}