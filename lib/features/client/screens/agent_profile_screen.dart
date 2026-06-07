import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fonaco/widgets/custom_app_bar.dart';
import 'package:fonaco/core/routes/app_routes.dart';
import 'package:fonaco/features/chat/chat_repository.dart';
import '../models/agent_model.dart';

/// Écran de profil d'agent Fonaqo (Production-Ready)
/// Affiche le profil complet d'un agent connecté et actif sur la plateforme
class AgentProfileScreen extends StatefulWidget {
  final String agentId;
  final Map<String, dynamic>? agent;

  const AgentProfileScreen({
    super.key,
    required this.agentId,
    this.agent,
  });

  @override
  State<AgentProfileScreen> createState() => _AgentProfileScreenState();
}

class _AgentProfileScreenState extends State<AgentProfileScreen> {
  final ChatRepository _chatRepository = ChatRepository();
  bool _isContacting = false;
  AgentModel? _agentModel;

  @override
  void initState() {
    super.initState();
    _initializeAgentModel();
  }

  void _initializeAgentModel() {
    if (widget.agent != null) {
      _agentModel = AgentModel.fromJson(widget.agent!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final agentData = widget.agent ?? {};
    final agent = _agentModel;

    // Fallback si le modèle n'est pas initialisé
    final name = agent?.name ??
        '${agentData['first_name'] ?? ''} ${agentData['last_name'] ?? ''}'
            .trim();
    final displayName = name.isEmpty ? 'Agent' : name;
    final specialty =
        agent?.specialty ?? agentData['specialty'] ?? 'Service général';
    final rating = agent?.rating ?? (agentData['rating']?.toDouble() ?? 4.5);
    final missions =
        agent?.completedMissions ?? (agentData['completed_missions'] ?? 0);
    final isTopChoice =
        agent?.isTopChoice ?? (agentData['is_top_choice'] == true);
    final avatarUrl = agent?.avatarUrl ??
        (agentData['avatar_url'] ?? agentData['avatar'] ?? '');
    final city = agent?.city ?? agentData['city'];
    final district = agent?.district ?? agentData['district'];
    final address = agent?.address ?? agentData['address'];
    final estimatedPrice =
        agent?.estimatedPrice ?? (agentData['estimated_price'] ?? '0 FCFA');

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: CustomAppBar.detailStack(
        title: displayName,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header premium avec avatar
            _buildHeader(
              displayName: displayName,
              specialty: specialty,
              avatarUrl: avatarUrl,
              isTopChoice: isTopChoice,
              rating: rating,
            ),

            const SizedBox(height: 24),

            // Card Stats
            _buildStatsCard(
              rating: rating,
              missions: missions,
              estimatedPrice: estimatedPrice,
            ),

            const SizedBox(height: 24),

            // Localisation
            if (city != null || district != null || address != null)
              _buildLocationSection(
                city: city,
                district: district,
                address: address,
              ),

            const SizedBox(height: 24),

            // Biographie (placeholder - champ manquant dans AgentModel)
            _buildBiographySection(),

            const SizedBox(height: 24),

            // Spécialités / Compétences
            _buildSpecialtiesSection(specialty: specialty),

            const SizedBox(height: 24),

            // Disponibilités (placeholder - champ manquant dans AgentModel)
            _buildAvailabilitySection(),

            const SizedBox(height: 32),

            // Bouton d'action principal
            _buildContactButton(agentId: widget.agentId),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({
    required String displayName,
    required String specialty,
    required String avatarUrl,
    required bool isTopChoice,
    required double rating,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: avatarUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: avatarUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.person,
                            color: Colors.grey[400], size: 40),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.person,
                            color: Colors.grey[400], size: 40),
                      ),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child:
                          Icon(Icons.person, color: Colors.grey[400], size: 40),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          // Informations
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    if (isTopChoice)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD400).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.workspace_premium,
                                size: 14, color: Color(0xFFFFD400)),
                            SizedBox(width: 4),
                            Text(
                              'Top',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  specialty,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ...List.generate(5, (index) {
                      return Icon(
                        index < rating.round() ? Icons.star : Icons.star_border,
                        size: 14,
                        color: const Color(0xFFFFD400),
                      );
                    }),
                    const SizedBox(width: 6),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard({
    required double rating,
    required int missions,
    required String estimatedPrice,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            icon: Icons.star,
            value: rating.toStringAsFixed(1),
            label: 'Note',
            color: const Color(0xFFFFD400),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            icon: Icons.check_circle,
            value: '$missions',
            label: 'Missions',
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            icon: Icons.attach_money,
            value: estimatedPrice,
            label: 'Tarif',
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection({
    String? city,
    String? district,
    String? address,
  }) {
    final locationParts = <String>[];
    if (district != null && district.isNotEmpty) locationParts.add(district);
    if (city != null && city.isNotEmpty) locationParts.add(city);
    if (address != null && address.isNotEmpty) locationParts.add(address);

    if (locationParts.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 8),
              const Text(
                'Zone d\'intervention',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...locationParts.map((part) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const SizedBox(width: 28),
                    Expanded(
                      child: Text(
                        part,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildBiographySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'À propos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Biographie non disponible. Cette information sera ajoutée prochainement.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialtiesSection({required String specialty}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spécialités',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip(specialty),
              _buildChip('Service professionnel'),
              _buildChip('Intervention rapide'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7C600).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Disponibilités',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Statut de disponibilité non disponible',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton({required String agentId}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isContacting ? null : () => _handleContact(agentId),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF7C600),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: _isContacting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              )
            : const Icon(Icons.chat, size: 20),
        label: Text(
          _isContacting ? 'Ouverture du chat...' : 'Contacter l\'agent',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _handleContact(String agentId) async {
    setState(() => _isContacting = true);

    try {
      // Note: ChatRepository.getOrCreateConversation nécessite un missionId
      // Pour un contact direct hors mission, nous devrons créer une conversation
      // avec l'agent directement. Pour l'instant, nous naviguons vers la liste
      // des conversations et affichons un message.

      if (mounted) {
        setState(() => _isContacting = false);

        // Navigation vers la liste des conversations
        // TODO: Implémenter la création de conversation directe avec agent
        // une fois que l'API supportera ce cas d'usage
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Fonctionnalité de contact direct en cours de développement'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigation temporaire vers la liste des conversations
        Navigator.pushNamed(context, AppRoutes.chatList);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isContacting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
