import 'package:flutter/material.dart';

import '../../widgets/custom_app_bar.dart';

/// Liste des notifications côté client (Requester).
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: const CustomAppBar.detailStack(
        detailTitleWidget: Text('Notifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: const [
          _NotifTile(
            title: "Votre agent est arrivé",
            subtitle: "Mairie d'Abidjan • Il est sur place depuis 2 min",
            time: 'Il y a 2 min',
            icon: Icons.directions_walk,
          ),
          SizedBox(height: 12),
          _NotifTile(
            title: "Mission publiée",
            subtitle: "Poste de Cocody • En attente d’acceptation",
            time: 'Aujourd’hui',
            icon: Icons.assignment_outlined,
          ),
          SizedBox(height: 12),
          _NotifTile(
            title: "Nouveau message",
            subtitle: "Julien B. • “Je suis en route.”",
            time: 'Hier',
            icon: Icons.chat_bubble_outline,
          ),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;

  const _NotifTile({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14)],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD400).withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.black),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(time, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

