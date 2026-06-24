import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:logger/logger.dart';
import 'package:fonaco/core/api/base_client.dart';

class AgentRankingScreen extends StatefulWidget {
  const AgentRankingScreen({super.key});

  @override
  State<AgentRankingScreen> createState() => _AgentRankingScreenState();
}

class _AgentRankingScreenState extends State<AgentRankingScreen> {
  final Logger _log = Logger();
  final BaseClient _baseClient = BaseClient();

  List<Map<String, dynamic>> _topAgents = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTopAgents();
  }

  Future<void> _loadTopAgents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _baseClient.get(
        'accounts/agents/top/',
        queryParameters: {'limit': '50'},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as List<dynamic>? ?? [];
        setState(() {
          _topAgents = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Erreur lors du chargement du classement';
          _isLoading = false;
        });
      }
    } catch (e, st) {
      _log.e('loadTopAgents', error: e, stackTrace: st);
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classement des agents'),
        backgroundColor: const Color(0xFFFFD400),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTopAgents,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_topAgents.isEmpty) {
      return const Center(
        child: Text('Aucun agent classé pour le moment'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTopAgents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _topAgents.length,
        itemBuilder: (context, index) {
          final agent = _topAgents[index];
          final rank = agent['rank'] as int? ?? (index + 1);
          final score = agent['score'] as num? ?? 0;
          final agentData = agent['agent'] as Map<String, dynamic>? ?? {};
          final name = agentData['user']?['first_name'] != null
              ? '${agentData['user']['first_name']} ${agentData['user']['last_name']}'
                  .trim()
              : agentData['user']?['username']?.toString() ?? 'Agent';
          final avatarUrl = agentData['user']?['avatar_url']?.toString();
          final rating = agentData['average_rating'] as num? ?? 0;
          final completedMissions = agentData['ratings_count'] as int? ?? 0;

          return _buildAgentCard(
            rank: rank,
            name: name,
            avatarUrl: avatarUrl,
            score: score,
            rating: rating,
            completedMissions: completedMissions,
          );
        },
      ),
    );
  }

  Widget _buildAgentCard({
    required int rank,
    required String name,
    String? avatarUrl,
    required num score,
    required num rating,
    required int completedMissions,
  }) {
    Color rankColor;
    IconData rankIcon;

    if (rank == 1) {
      rankColor = Colors.amber;
      rankIcon = Icons.emoji_events;
    } else if (rank == 2) {
      rankColor = Colors.grey;
      rankIcon = Icons.military_tech;
    } else if (rank == 3) {
      rankIcon = Icons.workspace_premium;
      rankColor = Colors.brown;
    } else {
      rankColor = Colors.blue;
      rankIcon = Icons.person;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Rank badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: rankColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: rank <= 3
                    ? Icon(rankIcon, color: rankColor, size: 28)
                    : Text(
                        '$rank',
                        style: TextStyle(
                          color: rankColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: avatarUrl != null
                  ? CachedNetworkImageProvider(avatarUrl) as ImageProvider
                  : null,
              child: avatarUrl == null
                  ? const Icon(Icons.person, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.check_circle,
                          size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        '$completedMissions missions',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Score
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${score.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: rankColor,
                  ),
                ),
                const Text(
                  'pts',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
