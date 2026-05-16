import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import 'package:fonaco/core/models/mission_model.dart';
import 'package:fonaco/core/routes/app_routes.dart';
import 'package:fonaco/core/providers/auth_provider.dart';
import 'package:fonaco/widgets/main_wrapper.dart';
import 'mission_repository.dart';
import 'screens/create_mission_screen.dart';

class MissionsScreen extends StatefulWidget {
  /// Contrôle si on affiche la liste des missions ou le flux de création.
  final ValueListenable<bool> showCreateMissionListenable;

  const MissionsScreen({super.key, required this.showCreateMissionListenable});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  final MissionRepository _repo = MissionRepository();
  List<MissionModel> _missions = [];
  bool _loading = true;
  bool _isFetching = false; // garde-fou réel (concurrence)
  String? _error;
  String _filter = 'all'; // 'all', 'ongoing', 'completed', 'cancelled'

  @override
  void initState() {
    super.initState();
    _loadMissions();
    // Écouter les changements pour rafraîchir la liste quand on quitte le mode création
    widget.showCreateMissionListenable.addListener(_onCreateModeChanged);
  }

  @override
  void dispose() {
    widget.showCreateMissionListenable.removeListener(_onCreateModeChanged);
    super.dispose();
  }

  void _onCreateModeChanged() {
    if (!widget.showCreateMissionListenable.value) {
      _loadMissions();
    }
  }

  Future<void> _loadMissions() async {
    // SÉCURITÉ : Éviter les fetchs concurrents (et non pas l'état UI initial)
    if (_isFetching) {
      return;
    }
    _isFetching = true;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      print('🔒 Utilisateur non authentifié, skip missions load');
      if (mounted) {
        setState(() {
          _loading = false;
          _missions = [];
          _error = auth.errorMessage ?? 'Veuillez vous connecter';
        });
      }
      _isFetching = false;
      return;
    }

    if (!mounted) {
      _isFetching = false;
      return;
    }
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
        _error = "Erreur de connexion aux missions";
        _loading = false;
      });
    } finally {
      _isFetching = false;
    }
  }

  /// Logique de filtrage des missions
  List<MissionModel> get _filteredMissions {
    switch (_filter) {
      case 'ongoing':
        return _missions
            .where((m) =>
                m.status == MissionStatus.PENDING ||
                m.status == MissionStatus.ACCEPTED ||
                m.status == MissionStatus.ON_THE_WAY ||
                m.status == MissionStatus.ARRIVED ||
                m.status == MissionStatus.IN_PROGRESS)
            .toList();
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
            child: CreateMissionScreen(),
          );
        }

        final filtered = _filteredMissions;

        return RefreshIndicator(
          onRefresh: _loadMissions,
          color: Colors.black,
          backgroundColor: const Color(0xFFFFD400),
          child: CustomScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(), // Permet le refresh même si le contenu est petit
            slivers: [
              // Sliver pour l'en-tête et les filtres
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Mes Missions",
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.black)),
                      const SizedBox(height: 16),
                      const MissionsPromoQueueCard(),
                      const SizedBox(height: 14),

                      // Filtres et Bouton Créer
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => MainShellScope.maybeOf(context)
                                  ?.openCreateMission(),
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
                              onTap: () =>
                                  setState(() => _filter = 'completed'),
                            ),
                            _CategoryChip(
                              label: "Annulées",
                              isActive: _filter == 'cancelled',
                              onTap: () =>
                                  setState(() => _filter = 'cancelled'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),

              // Sliver pour le contenu des missions
              if (_loading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (_error != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    child: _buildErrorState(),
                  ),
                )
              else if (filtered.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    child: _buildEmptyState(),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final mission = filtered[index];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
                        child: MissionCard(
                          title: mission.title,
                          type: mission.category ?? 'Mission',
                          status: mission.statusDisplay,
                          time: mission.timeAgo,
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.missionDetail,
                            arguments: {'missionId': mission.id},
                          ),
                        ),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),

              // Padding pour le bas
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.assignment_late_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('Aucune mission trouvée',
                style: TextStyle(color: Colors.grey, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Text(_error!, style: TextStyle(color: Colors.red[700], fontSize: 13)),
          const SizedBox(height: 8),
          TextButton(onPressed: _loadMissions, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _CategoryChip(
      {required this.label, required this.isActive, required this.onTap});

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

  const MissionCard(
      {super.key,
      required this.title,
      required this.type,
      required this.status,
      required this.time,
      this.onTap});

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
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Colors.black)),
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
    final s = status.toLowerCase();
    final isPending = s.contains('attente') || s.contains('pending');
    final isCancelled = s.contains('annulée') || s.contains('cancelled');

    Color bg = Colors.green[50]!;
    Color fg = Colors.green[800]!;

    if (isPending) {
      bg = Colors.orange[50]!;
      fg = Colors.orange[800]!;
    } else if (isCancelled) {
      bg = Colors.red[50]!;
      fg = Colors.red[800]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: fg, fontWeight: FontWeight.w900, fontSize: 10),
      ),
    );
  }
}

class MissionsPromoQueueCard extends StatelessWidget {
  const MissionsPromoQueueCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD400),
        borderRadius: BorderRadius.circular(30),
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
            child: const Icon(Icons.hourglass_bottom, color: Color(0xFFFFD400)),
          ),
        ],
      ),
    );
  }
}
