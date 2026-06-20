import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fonaco/core/providers/auth_provider.dart';
import 'package:fonaco/core/api/base_client.dart';
import 'package:logger/logger.dart';

/// Écran de fidélité et récompenses client
class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final BaseClient _api = BaseClient();
  final Logger _logger = Logger();
  
  Map<String, dynamic>? _rewardsData;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRewards();
  }

  Future<void> _loadRewards() async {
    try {
      final auth = context.read<AuthProvider>();
      if (!auth.isAuthenticated) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = 'Non connecté';
          });
        }
        return;
      }

      final response = await _api.get('client/rewards/');
      
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _rewardsData = response.data as Map<String, dynamic>;
            _loading = false;
            _error = null;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = 'Erreur chargement récompenses';
          });
        }
      }
    } catch (e) {
      _logger.e('Erreur chargement récompenses', error: e);
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Mes Récompenses',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadRewards,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : _rewardsData != null
                  ? _buildRewardsContent()
                  : const Center(child: Text('Aucune donnée de récompenses')),
    );
  }

  Widget _buildRewardsContent() {
    final points = _rewardsData!['points'] as int? ?? 0;
    final level = _rewardsData!['level'] as int? ?? 1;
    final missionsCompleted = _rewardsData!['missions_completed'] as int? ?? 0;
    final totalSpent = _rewardsData!['total_spent'] as num? ?? 0;
    final pointsToNextLevel = _rewardsData!['points_to_next_level'] as int? ?? 0;
    final badges = _rewardsData!['badges'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec points et niveau
          _LevelProgressCard(
            points: points,
            level: level,
            pointsToNextLevel: pointsToNextLevel,
          ),
          const SizedBox(height: 20),
          
          // Statistiques
          _StatsCard(
            missionsCompleted: missionsCompleted,
            totalSpent: totalSpent.toDouble(),
          ),
          const SizedBox(height: 20),
          
          // Badges
          const Text(
            'Mes Badges',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          _BadgesGrid(badges: badges),
        ],
      ),
    );
  }
}

class _LevelProgressCard extends StatelessWidget {
  final int points;
  final int level;
  final int pointsToNextLevel;

  const _LevelProgressCard({
    required this.points,
    required this.level,
    required this.pointsToNextLevel,
  });

  @override
  Widget build(BuildContext context) {
    final maxLevel = 10;
    final progress = level < maxLevel 
        ? pointsToNextLevel > 0 
            ? (points % 100) / 100.0 
            : 0.0
        : 1.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFD400),
            const Color(0xFFFFD400).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD400).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Niveau',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Niveau $level',
                  style: const TextStyle(
                    color: Color(0xFFFFD400),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '$points XP',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            level < maxLevel 
                ? '$pointsToNextLevel XP pour le niveau suivant'
                : 'Niveau maximum atteint !',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.black.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final int missionsCompleted;
  final double totalSpent;

  const _StatsCard({
    required this.missionsCompleted,
    required this.totalSpent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.check_circle,
              label: 'Missions',
              value: '$missionsCompleted',
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _StatItem(
              icon: Icons.payments,
              label: 'Dépensé',
              value: '${totalSpent.toStringAsFixed(0)} FCFA',
              color: const Color(0xFFFFD400),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
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
    );
  }
}

class _BadgesGrid extends StatelessWidget {
  final List<dynamic> badges;

  const _BadgesGrid({required this.badges});

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.emoji_events_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'Aucun badge débloqué',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Complétez des missions pour débloquer des badges !',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index] as Map<String, dynamic>;
        return _BadgeCard(badge: badge);
      },
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final Map<String, dynamic> badge;

  const _BadgeCard({required this.badge});

  @override
  Widget build(BuildContext context) {
    final name = badge['name'] as String? ?? 'Badge';
    final description = badge['description'] as String? ?? '';
    final icon = _getBadgeIcon(name);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD400), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD400).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFFFFD400), size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  IconData _getBadgeIcon(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('première') || lowerName.contains('first')) {
      return Icons.star;
    } else if (lowerName.contains('fidèle') || lowerName.contains('loyal')) {
      return Icons.favorite;
    } else if (lowerName.contains('vip')) {
      return Icons.verified;
    } else if (lowerName.contains('dépenseur') || lowerName.contains('spender')) {
      return Icons.payments;
    } else if (lowerName.contains('super')) {
      return Icons.diamond;
    }
    return Icons.emoji_events;
  }
}
