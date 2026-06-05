import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fonaco/core/services/cache_service.dart';
import 'package:fonaco/features/client/missions/mission_repository.dart';
import 'package:fonaco/widgets/custom_app_bar.dart';
import 'package:logger/logger.dart';

/// Écran affichant la liste des agents favoris du client
class FavoriteAgentsScreen extends StatefulWidget {
  const FavoriteAgentsScreen({super.key});

  @override
  State<FavoriteAgentsScreen> createState() => _FavoriteAgentsScreenState();
}

class _FavoriteAgentsScreenState extends State<FavoriteAgentsScreen> {
  final Logger _logger = Logger();
  final CacheService _cacheService = CacheService();
  final MissionRepository _missionRepository = MissionRepository();

  List<String> _favoriteAgentIds = [];
  List<Map<String, dynamic>> _agents = [];
  bool _isLoading = true;
  Set<String> _favoriteAgentIdsSet = {};

  @override
  void initState() {
    super.initState();
    _loadFavoriteAgents();
  }

  Future<void> _loadFavoriteAgents() async {
    setState(() => _isLoading = true);

    try {
      if (!_cacheService.isInitialized) {
        await _cacheService.init();
      }

      final favorites = _cacheService.getFavoriteAgents();
      _favoriteAgentIds = favorites;
      _favoriteAgentIdsSet = favorites.toSet();

      // Récupérer les profils complets des agents favoris
      if (favorites.isNotEmpty) {
        await _loadAgentProfiles(favorites);
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
      _logger.i('❤️ ${favorites.length} agents favoris chargés');
    } catch (e) {
      _logger.e('❌ Erreur chargement favoris: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAgentProfiles(List<String> agentIds) async {
    try {
      // Récupérer tous les agents disponibles et filtrer par IDs favoris
      final allAgents = await _missionRepository.fetchNearbyAgents(
        limit: 100, // Récupérer plus d'agents pour inclure les favoris
      );

      // Filtrer pour ne garder que les agents favoris
      final favoriteAgents = allAgents.where((agent) {
        final agentId = agent['id']?.toString() ?? '';
        return _favoriteAgentIdsSet.contains(agentId);
      }).toList();

      if (mounted) {
        setState(() {
          _agents = favoriteAgents;
        });
      }
      _logger.i('✅ ${favoriteAgents.length} profils agents récupérés');
    } catch (e) {
      _logger.e('❌ Erreur chargement profils agents: $e');
    }
  }

  void _toggleFavoriteAgent(String agentId) {
    _cacheService.toggleFavoriteAgent(agentId).then((_) {
      if (mounted) {
        setState(() {
          if (_favoriteAgentIdsSet.contains(agentId)) {
            _favoriteAgentIdsSet.remove(agentId);
            _favoriteAgentIds.remove(agentId);
            _agents.removeWhere((agent) => agent['id']?.toString() == agentId);
          } else {
            _favoriteAgentIdsSet.add(agentId);
            _favoriteAgentIds.add(agentId);
            // Recharger les profils pour inclure le nouvel agent favori
            _loadAgentProfiles(_favoriteAgentIds);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar.detailStack(
        title: 'Mes Agents Favoris',
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_favoriteAgentIds.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_border,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun agent favori',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ajoutez des agents à vos favoris pour les retrouver facilement.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _agents.length,
      itemBuilder: (context, index) {
        final agent = _agents[index];
        final agentId = agent['id']?.toString() ?? '';
        final agentName =
            '${agent['first_name'] ?? ''} ${agent['last_name'] ?? ''}'.trim();
        final avatarUrl = agent['avatar_url']?.toString();
        final rating = agent['rating']?.toString() ?? 'N/A';
        final isVerified = agent['is_verified'] == true;
        final specialties = agent['specialties'] as List<dynamic>? ?? [];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                      ? CachedNetworkImageProvider(avatarUrl) as ImageProvider
                      : null,
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? const Icon(Icons.person, color: Colors.grey, size: 32)
                      : null,
                ),
                const SizedBox(width: 16),
                // Info agent
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            agentName.isEmpty ? 'Agent' : agentName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF121212),
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.verified,
                              color: Colors.blue,
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Color(0xFFF7C600),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFF121212),
                            ),
                          ),
                        ],
                      ),
                      if (specialties.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: specialties.take(2).map<Widget>((spec) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                spec.toString(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                // Bouton favori
                IconButton(
                  icon: const Icon(
                    Icons.favorite,
                    color: Colors.red,
                  ),
                  onPressed: () => _toggleFavoriteAgent(agentId),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
