import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fonaco/core/models/mission_model.dart';
import 'package:fonaco/core/routes/app_routes.dart';
import 'package:fonaco/features/agent/providers/agent_provider.dart';
import 'package:fonaco/features/agent/widgets/rating_dialog.dart';
import 'package:go_router/go_router.dart';

/// Écran d'historique détaillé des missions de l'agent.
class AgentMissionHistoryScreen extends StatefulWidget {
  final bool embeddedInShell;

  const AgentMissionHistoryScreen({
    super.key,
    this.embeddedInShell = false,
  });

  @override
  State<AgentMissionHistoryScreen> createState() =>
      _AgentMissionHistoryScreenState();
}

class _AgentMissionHistoryScreenState extends State<AgentMissionHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<MissionModel> _completedMissions = [];
  List<MissionModel> _cancelledMissions = [];
  List<MissionModel> _disputedMissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMissionHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMissionHistory() async {
    setState(() => _isLoading = true);

    try {
      final repo = context.read<AgentProvider>().missionRepository;
      final results = await Future.wait([
        repo.getHistory(limit: 50),
        repo.getDisputed(limit: 50),
      ]);

      final history = results[0] as List<MissionModel>;
      final disputed = results[1] as List<MissionModel>;

      setState(() {
        _completedMissions = history
            .where((m) => m.status == MissionStatus.COMPLETED)
            .toList();
        _cancelledMissions = history
            .where((m) => m.status == MissionStatus.CANCELLED)
            .toList();
        _disputedMissions = disputed;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement historique: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabView = TabBarView(
      controller: _tabController,
      children: [
        _buildMissionsList(_completedMissions, 'terminées'),
        _buildMissionsList(_cancelledMissions, 'annulées'),
        _buildMissionsList(_disputedMissions, 'litiges'),
      ],
    );

    final tabBar = TabBar(
      controller: _tabController,
      labelColor: Colors.black,
      unselectedLabelColor: Colors.grey.shade600,
      indicatorColor: const Color(0xFFFFD400),
      indicatorWeight: 3,
      tabs: const [
        Tab(text: 'Terminées'),
        Tab(text: 'Annulées'),
        Tab(text: 'Litiges'),
      ],
    );

    if (widget.embeddedInShell) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Text(
              'Historique',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ),
          tabBar,
          Expanded(child: tabView),
        ],
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Historique des missions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        bottom: tabBar,
      ),
      body: tabView,
    );
  }

  Widget _buildMissionsList(List<MissionModel> missions, String type) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (missions.isEmpty) {
      return Center(
        child: Text(
          'Aucune mission $type',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMissionHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: missions.length,
        itemBuilder: (context, index) {
          return _MissionHistoryCard(
            mission: missions[index],
            onRefresh: _loadMissionHistory,
          );
        },
      ),
    );
  }
}

class _MissionHistoryCard extends StatelessWidget {
  final MissionModel mission;
  final VoidCallback onRefresh;

  const _MissionHistoryCard({
    required this.mission,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = mission.status == MissionStatus.COMPLETED;
    final isDisputed = mission.status == MissionStatus.DISPUTED;
    final formattedDate = mission.updatedAt != null
        ? _formatDate(mission.updatedAt!)
        : '';
    final formattedPrice = '${mission.price.toStringAsFixed(0)} FCFA';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  mission.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDisputed
                      ? Colors.orange.shade100
                      : isCompleted
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  mission.formattedStatus,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDisputed
                        ? Colors.orange.shade800
                        : isCompleted
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                  ),
                ),
              ),
            ],
          ),
          if (mission.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              mission.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.person_outline,
                  size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  mission.clientName ?? 'Client',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                formattedPrice,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: isCompleted
                      ? Colors.green.shade700
                      : Colors.grey.shade800,
                ),
              ),
            ],
          ),
          if (formattedDate.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              formattedDate,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isCompleted)
                OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => RatingDialog(
                        missionId: mission.id,
                        onRatingSubmitted: (_, __) => onRefresh(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.star_outline, size: 16),
                  label: const Text('Noter', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Color(0xFFE0B800)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              if (isCompleted) const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  context.push(AppRoutes.agentMissionDetail, extra: {'mission': mission},
                  );
                },
                icon: const Icon(Icons.info_outline, size: 16),
                label: const Text('Détails', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD400),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Aujourd\'hui';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
    return '${date.day}/${date.month}/${date.year}';
  }
}
