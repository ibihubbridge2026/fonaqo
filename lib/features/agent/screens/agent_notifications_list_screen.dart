import 'package:flutter/material.dart';
import '../widgets/agent_custom_header.dart';

class AgentNotificationsListScreen extends StatefulWidget {
  const AgentNotificationsListScreen({super.key});

  @override
  State<AgentNotificationsListScreen> createState() => _AgentNotificationsListScreenState();
}

class _AgentNotificationsListScreenState extends State<AgentNotificationsListScreen> {
  // Liste des notifications simulées
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'title': 'Nouvelle mission disponible',
      'message': 'Une mission de livraison vous attend près de votre position',
      'time': 'Il y a 5 min',
      'type': 'mission',
      'isRead': false,
      'icon': Icons.work_outline,
      'color': Colors.green,
    },
    {
      'id': '2',
      'title': 'Paiement reçu',
      'message': 'Votre paiement de 15 000 FCFA a été traité avec succès',
      'time': 'Il y a 1 heure',
      'type': 'payment',
      'isRead': false,
      'icon': Icons.payment,
      'color': Colors.blue,
    },
    {
      'id': '3',
      'title': 'Mission terminée',
      'message': 'Client satisfait - Note: 5/5',
      'time': 'Il y a 2 heures',
      'type': 'review',
      'isRead': true,
      'icon': Icons.star,
      'color': Colors.orange,
    },
    {
      'id': '4',
      'title': 'Rappel de mission',
      'message': 'Mission prévue à 14h00 - N\'oubliez pas vos documents',
      'time': 'Il y a 3 heures',
      'type': 'reminder',
      'isRead': true,
      'icon': Icons.alarm,
      'color': Colors.red,
    },
    {
      'id': '5',
      'title': 'Message de support',
      'message': 'Votre ticket a été résolu par notre équipe',
      'time': 'Hier',
      'type': 'support',
      'isRead': true,
      'icon': Icons.help_outline,
      'color': Colors.purple,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: const AgentCustomHeader(
        sectionTitle: 'Notifications',
      ),
      body: Column(
        children: [
          // Bouton pour marquer tout comme lu
          Container(
            margin: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_notifications.where((n) => !n['isRead']).length} non lues',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      for (var notification in _notifications) {
                        notification['isRead'] = true;
                      }
                    });
                  },
                  child: const Text(
                    'Tout marquer comme lu',
                    style: TextStyle(
                      color: Color(0xFFFFD400),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Liste des notifications
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return _buildNotificationTile(notification);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(Map<String, dynamic> notification) {
    return GestureDetector(
      onTap: () {
        setState(() {
          notification['isRead'] = true;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification['isRead'] ? Colors.white : const Color(0xFFFFF7CC),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icône de notification
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: notification['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                notification['icon'],
                color: notification['color'],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            
            // Contenu de la notification
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification['title'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: notification['isRead'] ? FontWeight.w500 : FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      if (!notification['isRead'])
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD400),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification['message'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notification['time'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
