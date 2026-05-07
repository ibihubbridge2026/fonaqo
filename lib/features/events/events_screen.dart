import 'package:flutter/material.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // Marge en bas pour le nav
      children: [
        const Text(
          "Mes Événements",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 20),
        // On passe maintenant un chemin d'image (asset ou network)
        _buildEventCard(
          "We Love Eya 2026",
          "15 Dec - 20:00",
          "Palais de la Culture",
          "File d'attente",
          "assets/images/events/event-wle.webp", // Exemple d'image locale
        ),
        _buildEventCard(
          "Festi Chill",
          "02 Jan - 09:00",
          "Hôtel Ivoire",
          "En attente",
          "assets/images/events/event-vd.jpg",
        ),
      ],
    );
  }

  Widget _buildEventCard(
      String title, String date, String place, String status, String imagePath) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          // --- ZONE IMAGE ---
          Container(
            height: 160, // Augmenté un peu pour mieux voir l'image
            width: double.infinity,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // L'image de l'événement
                  Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback si l'image n'est pas trouvée
                      return Container(
                        color: const Color(0xFFFFD400),
                        child: const Icon(Icons.broken_image, color: Colors.black26, size: 40),
                      );
                    },
                  ),
                  // Dégradé pour faire ressortir d'éventuels textes ou badges sur l'image
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // --- ZONE INFOS ---
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                          const SizedBox(width: 5),
                          Text("$date", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                          const SizedBox(width: 5),
                          Text(place, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                // Badge de statut
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: status == "En attente" ? Colors.orange[50] : Colors.green[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: status == "En attente" ? Colors.orange[800] : Colors.green[800],
                      fontWeight: FontWeight.w900,
                      fontSize: 9,
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}