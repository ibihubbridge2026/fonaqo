import 'package:flutter/material.dart';

class AgentStatCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Color? backgroundColor;

  const AgentStatCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
    this.iconColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: iconColor ?? const Color(0xFFE0B800),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF777777),
            ),
          ),
        ],
      ),
    );
  }
}
