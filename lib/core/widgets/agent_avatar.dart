import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Avatar agent avec image réseau, initiales ou icône par défaut.
class AgentAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String displayName;
  final double radius;

  const AgentAvatar({
    super.key,
    this.avatarUrl,
    required this.displayName,
    this.radius = 32,
  });

  String get _initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'A';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim();
    final hasUrl = url != null && url.isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFF3F4F6),
      backgroundImage: hasUrl ? CachedNetworkImageProvider(url) : null,
      child: hasUrl
          ? null
          : Text(
              _initials,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: radius * 0.55,
                color: const Color(0xFF374151),
              ),
            ),
    );
  }
}

/// Note agent numérique (reliability_score 0–100 ou rating 0–5).
double? parseAgentRating(dynamic raw) {
  if (raw == null) return null;
  final value = raw is num ? raw.toDouble() : double.tryParse(raw.toString());
  if (value == null || value <= 0) return null;
  if (value > 5) return (value / 20).clamp(0.0, 5.0);
  return value;
}

/// Note agent formatée (évite l'affichage brut « N/A »).
String formatAgentRating(dynamic raw) {
  if (raw == null) return '—';
  final value = raw is num ? raw.toDouble() : double.tryParse(raw.toString());
  if (value == null || value <= 0) return 'Nouveau';
  return value.toStringAsFixed(1);
}
