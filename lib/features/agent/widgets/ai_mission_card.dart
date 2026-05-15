import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/mission_model.dart';

/// Widget Carte Mission pour la Recherche IA (Agent)
class AiMissionCard extends StatelessWidget {
  final MissionModel mission;

  const AiMissionCard({super.key, required this.mission});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = AppColors(isDark: isDark);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Type + Statut
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  mission.type,
                  style: TextStyle(
                    color: colors.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              if (mission.isUrgent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flash_on, size: 14, color: colors.error),
                      const SizedBox(width: 4),
                      Text(
                        'URGENT',
                        style: TextStyle(
                          color: colors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Titre
          Text(
            mission.title,
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Localisation + Distance
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: colors.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  mission.location,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.near_me, size: 16, color: colors.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                mission.distance ?? '-',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Prix + Bouton Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gain estimé',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    mission.price,
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // Action : Accepter ou Voir détails
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Accepter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
