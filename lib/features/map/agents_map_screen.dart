import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:fonaco/features/client/missions/mission_repository.dart';
import '../../widgets/custom_app_bar.dart';

class AgentsMapScreen extends StatefulWidget {
  const AgentsMapScreen({super.key});

  @override
  State<AgentsMapScreen> createState() => _AgentsMapScreenState();
}

class _AgentsMapScreenState extends State<AgentsMapScreen> {
  final MissionRepository _missionRepo = MissionRepository();
  final MapController _mapController = MapController();
  List<Map<String, dynamic>> _agents = [];
  bool _loading = true;
  String? _error;
  int _selectedAgentIndex = 0;

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

      final agentsWithLocation = agents
          .where((agent) =>
              agent['latitude'] != null && agent['longitude'] != null)
          .toList();

      setState(() {
        _agents = agentsWithLocation;
        _loading = false;
      });

      // Centrer la carte sur le premier agent si disponible
      if (agentsWithLocation.isNotEmpty) {
        final firstAgent = agentsWithLocation[0];
        _mapController.move(
          LatLng(firstAgent['latitude'], firstAgent['longitude']),
          14.0,
        );
      }
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
        // FlutterMap
        Expanded(
          flex: 2,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(
                _agents[0]['latitude'],
                _agents[0]['longitude'],
              ),
              initialZoom: 14.0,
              minZoom: 10.0,
              maxZoom: 18.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.fonaco',
              ),
              MarkerLayer(
                markers: _agents.map((agent) {
                  final agentId = agent['id']?.toString() ?? '';
                  final lat = agent['latitude'] as double;
                  final lng = agent['longitude'] as double;
                  final index =
                      _agents.indexWhere((a) => a['id']?.toString() == agentId);

                  return Marker(
                    point: LatLng(lat, lng),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedAgentIndex = index;
                        });
                        _mapController.move(LatLng(lat, lng), 15.0);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: index == _selectedAgentIndex
                              ? const Color(0xFFFFD400)
                              : Colors.black,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // Bottom Sheet with Agent Cards
        Container(
          height: 250,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle for bottom sheet
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Horizontal scrollable agent cards
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _agents.length,
                  itemBuilder: (context, index) {
                    final agent = _agents[index];
                    return Container(
                      width: 280,
                      margin: const EdgeInsets.only(right: 12),
                      child: _AgentCard(
                        agent: agent,
                        isSelected: index == _selectedAgentIndex,
                        onTap: () {
                          setState(() {
                            _selectedAgentIndex = index;
                          });
                          _mapController.move(
                            LatLng(agent['latitude'], agent['longitude']),
                            15.0,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AgentCard extends StatelessWidget {
  final Map<String, dynamic> agent;
  final bool isSelected;
  final VoidCallback onTap;

  const _AgentCard({
    required this.agent,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name =
        '${agent['first_name'] ?? ''} ${agent['last_name'] ?? ''}'.trim();
    final specialty = agent['specialty'] ?? 'Agent terrain';
    final city = agent['city'] ?? 'Non spécifié';
    final address = agent['address'] ?? 'Non spécifié';
    final distance = agent['distance_km'];
    final reliability = agent['reliability_score'] ?? 100.0;
    final completionRate = agent['completion_rate'] ?? 0.0;
    final isVerified = agent['is_verified'] ?? false;
    final avatarUrl = agent['avatar_url'];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFFD400).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFD400) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
            ),
          ],
        ),
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
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl) : null,
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
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.verified,
                              size: 14,
                              color: Colors.blue[700],
                            ),
                          ],
                        ],
                      ),
                      Text(
                        specialty,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Distance si disponible
                if (distance != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${distance} km',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 8),

            // Localisation
            Row(
              children: [
                Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '$city${address != 'Non spécifié' ? ' • $address' : ''}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
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
                const SizedBox(width: 12),
                _StatItem(
                  icon: Icons.check_circle,
                  label: 'Taux',
                  value: '${completionRate.toStringAsFixed(0)}%',
                  color: Colors.green,
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
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 10,
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
