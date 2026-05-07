import 'package:flutter/material.dart';

class Step4MatchingAgents extends StatelessWidget {
  final VoidCallback onConfirmed;
  const Step4MatchingAgents({super.key, required this.onConfirmed});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 60),
        const SizedBox(height: 10),
        const Text("MISSION PUBLIÉE !", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
        const Text("AGENTS À PROXIMITÉ", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 30),
        
        _agentTile("Moussa D.", "4.9 ★ • 400m", "https://i.pravatar.cc/100?u=1"),
        const SizedBox(height: 12),
        _agentTile("Sarah B.", "4.8 ★ • 1.2km", "https://i.pravatar.cc/100?u=2", isAlpha: true),
      ],
    );
  }

  Widget _agentTile(String name, String info, String img, {bool isAlpha = false}) {
    return Opacity(
      opacity: isAlpha ? 0.6 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            CircleAvatar(radius: 25, backgroundImage: NetworkImage(img)),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(info, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: onConfirmed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 15),
              ),
              child: const Text("Confier", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}