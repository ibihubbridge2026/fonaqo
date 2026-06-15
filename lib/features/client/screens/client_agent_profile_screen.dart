import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import 'package:fonaco/core/providers/auth_provider.dart';
import 'package:fonaco/widgets/custom_app_bar.dart';

/// Écran de profil d'un agent accessible par le client
class ClientAgentProfileScreen extends StatelessWidget {
  static const String _fallbackAvatarAsset = 'assets/images/avatar/user.png';

  final String agentId;
  final String name;
  final String role;
  final String? avatarUrl;
  final List<String> expertiseTags;
  final double? rating;
  final bool isVerified;
  final bool isOnline;

  final bool showSelectAgentButton;

  const ClientAgentProfileScreen({
    super.key,
    required this.agentId,
    required this.name,
    required this.role,
    this.avatarUrl,
    this.expertiseTags = const [],
    this.rating,
    this.isVerified = false,
    this.isOnline = false,
    this.showSelectAgentButton = true,
  });

  factory ClientAgentProfileScreen.fromRouteArguments(
    Map<String, dynamic>? args,
  ) {
    final agent = args?['agent'] as Map<String, dynamic>? ?? {};
    final agentId =
        args?['agentId']?.toString() ?? agent['id']?.toString() ?? '';
    final name =
        '${agent['first_name'] ?? ''} ${agent['last_name'] ?? ''}'.trim();
    final displayName = name.isEmpty ? 'Agent' : name;
    final expertiseTags = (agent['expertise_tags'] as List<dynamic>?)
            ?.map((tag) => tag.toString())
            .toList() ??
        const <String>[];
    final role = agent['specialty']?.toString() ??
        (expertiseTags.isNotEmpty ? expertiseTags.first : 'Agent Fonaqo');
    final rating = (agent['rating'] as num?)?.toDouble();

    final showSelect = args?['showSelectAgentButton'] != false;

    return ClientAgentProfileScreen(
      agentId: agentId,
      name: displayName,
      role: role,
      avatarUrl: agent['avatar_url']?.toString(),
      expertiseTags: expertiseTags,
      rating: rating,
      isVerified: agent['is_verified'] == true,
      isOnline: agent['is_online'] == true,
      showSelectAgentButton: showSelect,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAgentUser = context.watch<AuthProvider>().isAgent;
    final showSelect = showSelectAgentButton && !isAgentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar.detailStack(
        title: 'Profil Agent',
        detailTrailingActions: [
          IconButton(
            icon: Icon(
              isOnline ? Icons.circle : Icons.circle_outlined,
              color: isOnline ? Colors.green : Colors.grey,
              size: 12,
            ),
            onPressed: null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar et informations principales
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        child: ClipOval(
                          child: _buildAvatarImage(),
                        ),
                      ),
                      if (isVerified)
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(2),
                          child: const Icon(
                            Icons.verified,
                            color: Colors.blue,
                            size: 24,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    role,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (rating != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.star,
                          color: Color(0xFFFFD400),
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating!.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Tags d'expertise
            if (expertiseTags.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Expertise',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: expertiseTags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD400).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFFD400),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF715D00),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 30),
            ],
            // Statistiques
            _buildStatRow('Missions complétées', '125'),
            _buildStatRow('Taux de réponse', '98%'),
            _buildStatRow('Temps de réponse moyen', '5 min'),
            const SizedBox(height: 30),
            // Section À propos
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'À propos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Agent professionnel et vérifié, spécialisé dans les services de proximité. Je m\'engage à fournir un service de qualité avec ponctualité et professionnalisme.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 30),
            if (showSelect) ...[
            // Bouton de sélection (client uniquement)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Agent sélectionné pour votre mission'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle, size: 22),
                  label: const Text(
                    'Sélectionner cet agent',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD400),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ],
            // Bouton contact
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Navigation vers le chat
                  },
                  icon: const FaIcon(
                    FontAwesomeIcons.commentDots,
                    size: 20,
                  ),
                  label: const Text(
                    'Contacter',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarImage() {
    final url = avatarUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        placeholder: (_, __) => Image.asset(
          _fallbackAvatarAsset,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
        errorWidget: (_, __, ___) => Image.asset(
          _fallbackAvatarAsset,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.person,
            color: Colors.black54,
            size: 60,
          ),
        ),
      );
    }

    return Image.asset(
      _fallbackAvatarAsset,
      width: 120,
      height: 120,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(
        Icons.person,
        color: Colors.black54,
        size: 60,
      ),
    );
  }
}
