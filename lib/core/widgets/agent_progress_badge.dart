import 'package:flutter/material.dart';

/// Badge de progression agent (style Duolingo / gamification).
class AgentProgressBadge extends StatelessWidget {
  final Map<String, dynamic>? badge;

  const AgentProgressBadge({super.key, this.badge});

  static Color colorFromHex(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFFCD7F32);
    final value = hex.replaceFirst('#', '');
    if (value.length == 6) {
      return Color(int.parse('FF$value', radix: 16));
    }
    return const Color(0xFFCD7F32);
  }

  static IconData iconForTier(String? tier) {
    switch (tier) {
      case 'legend':
        return Icons.military_tech_rounded;
      case 'sapphire':
        return Icons.diamond_outlined;
      case 'platinum':
        return Icons.workspace_premium_outlined;
      case 'gold':
        return Icons.emoji_events_outlined;
      case 'silver':
        return Icons.shield_outlined;
      case 'bronze':
      default:
        return Icons.star_border_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (badge == null || badge!['label'] == null) {
      return const SizedBox.shrink();
    }

    final label = badge!['label']?.toString() ?? '';
    final tier = badge!['tier']?.toString();
    final color = colorFromHex(badge!['color']?.toString());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconForTier(tier), size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
