import 'package:flutter/material.dart';
import 'package:fonaco/features/client/missions/mission_repository.dart';
import '../../widgets/custom_app_bar.dart';

class AgentsMapScreen extends StatefulWidget {
  const AgentsMapScreen({super.key});

  @override
  State<AgentsMapScreen> createState() => _AgentsMapScreenState();
}

class _AgentsMapScreenState extends State<AgentsMapScreen> {
  final MissionRepository _missionRepo = MissionRepository();
  List<Map<String, dynamic>> _agents = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAgents();
  }

  Future<void> _loadAgents() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final agents = await _missionRepo.fetchAgentSuggestions();
      if (!mounted) return;
      setState(() {
        _agents = agents.where((agent) => 
          agent['latitude'] != null && 
          agent['longitude'] != null
        ).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: const CustomAppBar.detailStack(
        title: 'Carte des agents',
        detailTitleWidget: Text(
          "Agents disponibles",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: TextStyle(color: Colors.red[700])),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAgents,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_agents.isEmpty) {
      return const Center(
        child: Text('Aucun agent trouvé avec localisation'),
      );
    }

    return Column(
      children: [
        // Header avec le nombre d'agents
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                '${_agents.length} agents trouvés',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
        
        // Liste des agents avec localisation
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _agents.length,
            itemBuilder: (context, index) {
              final agent = _agents[index];
              return _AgentCard(agent: agent);
            },
          ),
        ),
      ],
    );
  }
}

class _AgentCard extends StatelessWidget {
  final Map<String, dynamic> agent;

  const _AgentCard({required this.agent});

  @override
  Widget build(BuildContext context) {
    final name = '${agent['first_name'] ?? ''} ${agent['last_name'] ?? ''}'.trim();
    final specialty = agent['specialty'] ?? 'Agent terrain';
    final city = agent['city'] ?? 'Non spécifié';
    final address = agent['address'] ?? 'Non spécifié';
    final distance = agent['distance_km'];
    final reliability = agent['reliability_score'] ?? 100.0;
    final completionRate = agent['completion_rate'] ?? 0.0;
    final isVerified = agent['is_verified'] ?? false;
    final avatarUrl = agent['avatar_url'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec avatar et infos principales
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue[100],
                  backgroundImage: avatarUrl != null 
                    ? NetworkImage(avatarUrl) 
                    : null,
                  child: avatarUrl == null
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'A',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
                ),
                const SizedBox(width: 12),
                
                // Infos principales
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name.isNotEmpty ? name : 'Agent',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.verified,
                              size: 16,
                              color: Colors.blue[700],
                            ),
                          ],
                        ],
                      ),
                      Text(
                        specialty,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Distance si disponible
                if (distance != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${distance} km',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Localisation
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '$city${address != 'Non spécifié' ? ' • $address' : ''}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Stats
            Row(
              children: [
                _StatItem(
                  icon: Icons.star,
                  label: 'Fiabilité',
                  value: '${reliability.toStringAsFixed(0)}%',
                  color: Colors.orange,
                ),
                const SizedBox(width: 16),
                _StatItem(
                  icon: Icons.check_circle,
                  label: 'Taux de completion',
                  value: '${completionRate.toStringAsFixed(0)}%',
                  color: Colors.green,
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chat bientôt disponible')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.blue[700]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Contacter',
                      style: TextStyle(color: Colors.blue[700]),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Mission bientôt disponible')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Mission'),
                  ),
                ),
              ],
            ),
          ],
        ),
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
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
