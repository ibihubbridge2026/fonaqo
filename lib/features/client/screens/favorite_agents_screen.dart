import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fonaco/core/providers/favorites_provider.dart';
import 'package:fonaco/core/services/cache_service.dart';
import 'package:fonaco/features/client/missions/mission_repository.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

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

  List<Map<String, dynamic>> _agents = [];
  bool _isLoading = true;

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

      final favoritesProvider =
          Provider.of<FavoritesProvider>(context, listen: false);
      await favoritesProvider.init();

      final favorites = favoritesProvider.favoriteAgentIds.toList();

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

      final favoritesProvider =
          Provider.of<FavoritesProvider>(context, listen: false);

      // Filtrer pour ne garder que les agents favoris
      final favoriteAgents = allAgents.where((agent) {
        final agentId = agent['id']?.toString() ?? '';
        return favoritesProvider.isFavorite(agentId);
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
    final favoritesProvider =
        Provider.of<FavoritesProvider>(context, listen: false);
    favoritesProvider.toggleFavorite(agentId).then((_) {
      if (mounted) {
        setState(() {
          if (!favoritesProvider.isFavorite(agentId)) {
            _agents.removeWhere((agent) => agent['id']?.toString() == agentId);
          } else {
            // Recharger les profils pour inclure le nouvel agent favori
            _loadAgentProfiles(favoritesProvider.favoriteAgentIds.toList());
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mes agents favoris',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    if (favoritesProvider.favoriteAgentIds.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite_border,
                  size: 64,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Aucun agent favori',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Ajoutez des agents à vos favoris depuis le dashboard pour les retrouver facilement ici.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_agents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                'Agents favoris introuvables',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Les agents que vous avez ajoutés en favori ne sont pas disponibles actuellement.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadFavoriteAgents,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD400),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Réessayer'),
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
