import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fonaco/core/models/mission_model.dart';
import 'package:fonaco/core/routes/app_routes.dart';
import 'package:fonaco/features/agent/presentation/dashboard/widgets/mission_card.dart';
import 'package:fonaco/features/agent/providers/agent_provider.dart';
import 'package:fonaco/features/agent/widgets/shimmer_loading_card.dart';
import 'package:go_router/go_router.dart';

/// Page Missions agent : recherche, filtres et onglets Disponibles / Attribué / En cours.
class AgentMissionsScreen extends StatefulWidget {
  const AgentMissionsScreen({super.key});

  @override
  State<AgentMissionsScreen> createState() => _AgentMissionsScreenState();
}

class _AgentMissionsScreenState extends State<AgentMissionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _geoFilter = 'all';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final provider = context.read<AgentProvider>();
    await Future.wait([
      provider.fetchAvailableMissions(filterByZone: _geoFilter == 'zone'),
      provider.fetchAssignedMissions(),
      provider.fetchActiveMissions(),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  List<MissionModel> _filter(List<MissionModel> missions) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return missions;
    return missions.where((m) {
      final title = m.title.toLowerCase();
      final address = (m.address ?? m.pickupAddress ?? '').toLowerCase();
      final client = (m.clientName ?? '').toLowerCase();
      return title.contains(q) || address.contains(q) || client.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AgentProvider>();
    final available = _filter(provider.availableMissions);
    final assigned = _filter(provider.assignedMissions);
    final active = _filter(provider.activeMissions);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Rechercher une mission...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _FilterChip(
                label: 'Toutes',
                selected: _geoFilter == 'all',
                onTap: () async {
                  setState(() => _geoFilter = 'all');
                  await _load();
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Proche de moi',
                selected: _geoFilter == 'near',
                onTap: () async {
                  setState(() => _geoFilter = 'near');
                  await _load();
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Ma zone',
                selected: _geoFilter == 'zone',
                onTap: () async {
                  setState(() => _geoFilter = 'zone');
                  await _load();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF000000),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFFFD400),
          indicatorWeight: 3,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: 'Disponibles (${available.length})'),
            Tab(text: 'Attribué (${assigned.length})'),
            Tab(text: 'En cours (${active.length})'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _MissionList(
                missions: available,
                loading: _loading,
                showAccept: true,
                onRefresh: _load,
                empty: 'Aucune mission disponible dans cette zone.',
              ),
              _MissionList(
                missions: assigned,
                loading: _loading,
                showAccept: true,
                showDecline: true,
                onRefresh: _load,
                empty: 'Aucune mission ne vous a été attribuée.',
              ),
              _MissionList(
                missions: active,
                loading: _loading,
                showAccept: false,
                onRefresh: _load,
                empty: 'Aucune mission en cours.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFFFFD400),
      checkmarkColor: Colors.black,
      labelStyle: TextStyle(
        fontWeight: selected ? FontWeight.bold : FontWeight.w500,
        color: Colors.black87,
      ),
    );
  }
}

class _MissionList extends StatelessWidget {
  final List<MissionModel> missions;
  final bool loading;
  final bool showAccept;
  final bool showDecline;
  final Future<void> Function() onRefresh;
  final String empty;

  const _MissionList({
    required this.missions,
    required this.loading,
    required this.showAccept,
    this.showDecline = false,
    required this.onRefresh,
    required this.empty,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: List.generate(
          3,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: ShimmerLoadingCard(
              width: double.infinity,
              height: 140,
              borderRadius: BorderRadius.all(Radius.circular(22)),
            ),
          ),
        ),
      );
    }

    if (missions.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: const Color(0xFFFFD400),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            Center(
              child: Text(empty, style: TextStyle(color: Colors.grey.shade600)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: const Color(0xFFFFD400),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: missions.length,
        itemBuilder: (context, index) {
          final mission = missions[index];
          return MissionCard(
            key: ValueKey('list-${mission.id}'),
            mission: mission,
            showAcceptButton: showAccept,
            showDeclineButton: showDecline,
            onConflict: onRefresh,
            onMissionAccepted: onRefresh,
            onDeclined: onRefresh,
            onTap: () => context.push(AppRoutes.agentMissionDetail, extra: {'mission': mission},
            ),
          );
        },
      ),
    );
  }
}
