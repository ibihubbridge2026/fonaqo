import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../../core/models/mission_model.dart';
import '../../core/routes/app_routes.dart';
import '../../core/models/mission_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../widgets/main_wrapper.dart';
<<<<<<< HEAD
import '../missions/mission_repository.dart';
=======
import 'mission_repository.dart';
>>>>>>> baf250f (mmisse a jour ddu gradle)
import 'screens/create_mission_screen.dart';

class MissionsScreen extends StatefulWidget {
  /// Contrôle si on affiche la liste des missions ou le flux de création.
  final ValueListenable<bool> showCreateMissionListenable;

  const MissionsScreen({super.key, required this.showCreateMissionListenable});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
<<<<<<< HEAD
  final MissionRepository _missionRepository = MissionRepository();
  List<MissionModel> _allMissions = [];
  List<MissionModel> _filteredMissions = [];
  bool _isLoading = true;
  String _selectedFilter = "Toutes";

  final List<String> _filters = ["Toutes", "En cours", "Terminées", "Annulées"];
=======
  final MissionRepository _repo = MissionRepository();
  List<MissionModel> _missions = [];
  bool _loading = true;
  String? _error;
  String _filter = 'all'; // all, ongoing, completed, cancelled
>>>>>>> baf250f (mmisse a jour ddu gradle)

  @override
  void initState() {
    super.initState();
    _loadMissions();
<<<<<<< HEAD
  }

  @override
  void didUpdateWidget(MissionsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recharger les missions lorsque le widget est mis à jour (retour sur la page)
    _loadMissions();
  }

  Future<void> _loadMissions() async {
    setState(() => _isLoading = true);

    try {
      final missions = await _missionRepository.fetchMissionsList();
      if (mounted) {
        setState(() {
          _allMissions = missions;
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des missions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilter() {
    switch (_selectedFilter) {
      case "En cours":
        _filteredMissions = _allMissions
=======
    // Listen to create mode changes to refresh when coming back
    widget.showCreateMissionListenable.addListener(_onCreateModeChanged);
  }

  @override
  void dispose() {
    widget.showCreateMissionListenable.removeListener(_onCreateModeChanged);
    super.dispose();
  }

  void _onCreateModeChanged() {
    // When switching back from create mode, refresh
    if (!widget.showCreateMissionListenable.value) {
      _loadMissions();
    }
  }

  Future<void> _loadMissions() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final missions = await _repo.fetchMissionsList();
      if (!mounted) return;
      setState(() {
        _missions = missions;
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

  List<MissionModel> get _filteredMissions {
    switch (_filter) {
      case 'ongoing':
        return _missions
>>>>>>> baf250f (mmisse a jour ddu gradle)
            .where((m) =>
                m.status == MissionStatus.PENDING ||
                m.status == MissionStatus.ACCEPTED ||
                m.status == MissionStatus.ON_THE_WAY ||
                m.status == MissionStatus.ARRIVED ||
                m.status == MissionStatus.IN_PROGRESS)
            .toList();
<<<<<<< HEAD
        break;
      case "Terminées":
        _filteredMissions = _allMissions
            .where((m) => m.status == MissionStatus.COMPLETED)
            .toList();
        break;
      case "Annulées":
        _filteredMissions = _allMissions
            .where((m) => m.status == MissionStatus.CANCELLED)
            .toList();
        break;
      case "Toutes":
      default:
        _filteredMissions = List.from(_allMissions);
        break;
=======
      case 'completed':
        return _missions
            .where((m) => m.status == MissionStatus.COMPLETED)
            .toList();
      case 'cancelled':
        return _missions
            .where((m) =>
                m.status == MissionStatus.CANCELLED ||
                m.status == MissionStatus.DISPUTED)
            .toList();
      default:
        return _missions;
>>>>>>> baf250f (mmisse a jour ddu gradle)
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.showCreateMissionListenable,
      builder: (context, isCreating, _) {
        if (isCreating) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: SizedBox.expand(
              child: CreateMissionScreen(),
            ),
          );
        }

<<<<<<< HEAD
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            const Text("Mes Missions",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            const MissionsPromoQueueCard(),
            const SizedBox(height: 14),

            // Barre catégories + bouton créer (dans le shell -> footer conservé)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () =>
                        MainShellScope.maybeOf(context)?.openCreateMission(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("CRÉER"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD400),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ..._filters.map(
                    (filter) => _CategoryChip(
                      label: filter,
                      isActive: _selectedFilter == filter,
                      onTap: () {
                        setState(() {
                          _selectedFilter = filter;
                          _applyFilter();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_filteredMissions.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'Aucune mission $_selectedFilter',
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              )
            else
              ..._filteredMissions.map(
                (mission) => MissionCard(
                  title: mission.title,
                  type: mission.formattedStatus,
                  status: mission.formattedStatus,
                  time: mission.createdAt != null
                      ? '${DateTime.now().difference(mission.createdAt!).inHours}h'
                      : 'Recent',
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.missionDetail,
                    arguments: {'missionId': mission.id},
                  ),
                ),
              ),
          ],
=======
        final filtered = _filteredMissions;

        return RefreshIndicator(
          onRefresh: _loadMissions,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            children: [
              const Text("Mes Missions",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              const MissionsPromoQueueCard(),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () =>
                          MainShellScope.maybeOf(context)?.openCreateMission(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("CRÉER"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD400),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _CategoryChip(
                      label: "Toutes",
                      isActive: _filter == 'all',
                      onTap: () => setState(() => _filter = 'all'),
                    ),
                    _CategoryChip(
                      label: "En cours",
                      isActive: _filter == 'ongoing',
                      onTap: () => setState(() => _filter = 'ongoing'),
                    ),
                    _CategoryChip(
                      label: "Terminées",
                      isActive: _filter == 'completed',
                      onTap: () => setState(() => _filter = 'completed'),
                    ),
                    _CategoryChip(
                      label: "Annulées",
                      isActive: _filter == 'cancelled',
                      onTap: () => setState(() => _filter = 'cancelled'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Text(_error!,
                          style:
                              TextStyle(color: Colors.red[700], fontSize: 13)),
                      const SizedBox(height: 8),
                      TextButton(
                          onPressed: _loadMissions,
                          child: const Text('Réessayer')),
                    ],
                  ),
                )
              else if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text('Aucune mission',
                        style: TextStyle(color: Colors.grey, fontSize: 15)),
                  ),
                )
              else
                ...filtered.map((m) => MissionCard(
                      title: m.title,
                      type: m.description,
                      status: m.statusDisplay,
                      time: m.timeAgo,
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.missionDetail,
                        arguments: {'missionId': m.id},
                      ),
                    )),
            ],
          ),
>>>>>>> baf250f (mmisse a jour ddu gradle)
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

<<<<<<< HEAD
  const _CategoryChip({
    required this.label,
    required this.isActive,
    this.onTap,
  });
=======
  const _CategoryChip(
      {required this.label, required this.isActive, this.onTap});
>>>>>>> baf250f (mmisse a jour ddu gradle)

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class MissionCard extends StatelessWidget {
  final String title;
  final String type;
  final String status;
  final String time;
  final VoidCallback? onTap;

  const MissionCard({
    super.key,
    required this.title,
    required this.type,
    required this.status,
    required this.time,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD400).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.assignment_outlined,
                  color: Color(0xFFFFD400)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text("$type • $time",
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            _StatusBadge(status: status),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isPending = status.toLowerCase().contains('attente');
    final bg = isPending ? Colors.orange[50] : Colors.green[50];
    final fg = isPending ? Colors.orange[800] : Colors.green[800];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(
        status,
        style: TextStyle(color: fg, fontWeight: FontWeight.w900, fontSize: 10),
      ),
    );
  }
}

/// Carte promo (style screenshot) : “Faites la queue à votre place”.
class MissionsPromoQueueCard extends StatelessWidget {
  const MissionsPromoQueueCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD400),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 6))
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              "Faites la queue à\nvotre place",
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w900, height: 1.1),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
                color: Colors.black, shape: BoxShape.circle),
            child: ClipOval(
              child: Image.asset(
                'favicon.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.hourglass_bottom,
                    color: Color(0xFFFFD400)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
