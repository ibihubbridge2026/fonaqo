import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../models/agent_model.dart';

/// Widget Carte Agent pour la Recherche IA
class AiAgentCard extends StatelessWidget {
  final AgentModel agent;

  const AiAgentCard({super.key, required this.agent});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = AppColors(isDark: isDark);

    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  agent.avatarUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 64,
                    height: 64,
                    color: colors.surfaceContainer,
                    child: Icon(Icons.person, color: colors.onSurfaceVariant),
                  ),
                ),
              ),
              Positioned(
                bottom: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 12, color: colors.onPrimary),
                      const SizedBox(width: 2),
                      Text(
                        agent.rating.toStringAsFixed(1),
                        style: TextStyle(
                          color: colors.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(width: 16),
          
          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        agent.name,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (agent.isTopChoice)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.secondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'TOP IA',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  agent.specialty,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${agent.completedMissions} missions réussies',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Prix
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                agent.estimatedPrice,
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              Text(
                'Estimation',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
