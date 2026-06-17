import 'package:flutter/material.dart';
import 'package:fonaco/core/providers/favorites_provider.dart';
import 'package:fonaco/core/providers/auth_provider.dart';
import 'package:fonaco/core/services/cache_service.dart';
import 'package:fonaco/core/widgets/agent_avatar.dart';
import 'package:fonaco/features/client/screens/client_agent_profile_screen.dart';
import 'package:fonaco/features/client/missions/mission_repository.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

/// Écran affichant la liste des agents favoris du client.
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

      final auth = Provider.of<AuthProvider>(context, listen: false);
      final favoritesProvider =
          Provider.of<FavoritesProvider>(context, listen: false);
      if (auth.currentUser?.id != null) {
        await favoritesProvider.init(auth.currentUser!.id);
      }

      final favorites = favoritesProvider.favoriteAgentIds.toList();

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
      final allAgents = await _missionRepository.fetchAgentSuggestions(
        limit: 100,
      );

      final favoritesProvider =
          Provider.of<FavoritesProvider>(context, listen: false);

      final favoriteAgents = allAgents.where((agent) {
        final agentId = agent['id']?.toString() ?? '';
        return favoritesProvider.isFavorite(agentId);
      }).toList();

      if (mounted) {
        setState(() {
          _agents = favoriteAgents;
        });
      }
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
            _loadAgentProfiles(favoritesProvider.favoriteAgentIds.toList());
          }
        });
      }
    });
  }

  String _agentDisplayName(Map<String, dynamic> agent) {
    final first = agent['first_name']?.toString().trim() ?? '';
    final last = agent['last_name']?.toString().trim() ?? '';
    final full = '$first $last'.trim();
    if (full.isNotEmpty) return full;
    final username = agent['username']?.toString().trim();
    if (username != null && username.isNotEmpty) return username;
    return 'Agent Fonaqo';
  }

  List<String> _agentSpecialties(Map<String, dynamic> agent) {
    final specialties = agent['specialties'];
    if (specialties is List && specialties.isNotEmpty) {
      return specialties.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    final specialty = agent['specialty']?.toString().trim();
    if (specialty != null && specialty.isNotEmpty) {
      return [specialty];
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mes agents favoris',
          style: TextStyle(
            color: Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFD400)),
      );
    }

    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    if (favoritesProvider.favoriteAgentIds.isEmpty) {
      return _emptyState(
        icon: Icons.favorite_border,
        title: 'Aucun agent favori',
        subtitle:
            'Ajoutez des agents à vos favoris depuis le dashboard pour les retrouver facilement ici.',
      );
    }

    if (_agents.isEmpty) {
      return _emptyState(
        icon: Icons.search_off,
        title: 'Agents favoris introuvables',
        subtitle:
            'Les agents que vous avez ajoutés en favori ne sont pas disponibles actuellement.',
        action: ElevatedButton(
          onPressed: _loadFavoriteAgents,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD400),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Réessayer'),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _agents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final agent = _agents[index];
        final agentId = agent['id']?.toString() ?? '';
        final displayName = _agentDisplayName(agent);
        final avatarUrl = agent['avatar_url']?.toString();
        final rating = formatAgentRating(
          agent['reliability_score'] ?? agent['rating'],
        );
        final isVerified = agent['is_verified'] == true;
        final specialties = _agentSpecialties(agent);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEEEEE)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    AgentAvatar(
                      avatarUrl: avatarUrl,
                      displayName: displayName,
                      radius: 28,
                    ),
                    const SizedBox(width: 14),
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
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: Color(0xFF121212),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isVerified)
                                const Padding(
                                  padding: EdgeInsets.only(left: 6),
                                  child: Icon(
                                    Icons.verified,
                                    color: Color(0xFF2563EB),
                                    size: 16,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFF7C600),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                rating,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                          if (specialties.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: specialties.take(2).map((spec) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    spec,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.favorite, color: Color(0xFFEF4444)),
                      onPressed: () => _toggleFavoriteAgent(agentId),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClientAgentProfileScreen(
                            agentId: agentId,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Consulter le profil',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Icon(icon, size: 56, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF121212),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action,
            ],
          ],
        ),
      ),
    );
  }
}
