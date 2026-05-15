import 'package:flutter/material.dart';

/// Widget pour indiquer visuellement l'état d'un message (en attente/envoyé)
class PendingMessageIndicator extends StatelessWidget {
  final bool isPending;
  final String? timestamp;

  const PendingMessageIndicator({
    super.key,
    required this.isPending,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    if (isPending) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Horloge grise pour message en attente
          Icon(
            Icons.access_time,
            size: 12,
            color: Colors.grey.shade500,
          ),
          const SizedBox(width: 4),
          Text(
            'En attente',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Coche bleue pour message envoyé
          Icon(
            Icons.check_circle,
            size: 12,
            color: Colors.blue.shade600,
          ),
          const SizedBox(width: 4),
          if (timestamp != null)
            Text(
              _formatTimestamp(timestamp!),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
        ],
      );
    }
  }

  /// Formate le timestamp pour l'affichage
  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'À l\'instant';
      } else if (difference.inMinutes < 60) {
        return 'Il y a ${difference.inMinutes} min';
      } else if (difference.inHours < 24) {
        return 'Il y a ${difference.inHours}h';
      } else {
        return '${dateTime.day}/${dateTime.month}';
      }
    } catch (e) {
      return timestamp;
    }
  }
}
