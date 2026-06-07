import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

import 'package:fonaco/core/models/mission_model.dart';
import 'package:fonaco/core/routes/app_routes.dart';
import 'package:fonaco/core/providers/auth_provider.dart';
import 'package:fonaco/core/services/cache_service.dart';
import 'package:fonaco/core/widgets/skeleton_loading.dart';
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
  final ScrollController _scrollController = ScrollController();
  final CacheService _cacheService = CacheService();
  final Logger _logger = Logger();
  List<MissionModel> _missions = [];
  bool _loading = true;
  bool _isFetching = false; // garde-fou réel (concurrence)
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMore = true;
  String? _error;
  String _filter = 'all'; // 'all', 'ongoing', 'completed', 'cancelled'

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    // Initialiser l'état de chargement avant l'appel API
    setState(() {
      _loading = true;
      _error = null;
    });
    // Charger les missions avec un délai pour éviter les problèmes de timing
    Future.microtask(() => _loadMissions());
    // Écouter les changements pour rafraîchir la liste quand on quitte le mode création
    widget.showCreateMissionListenable.addListener(_onCreateModeChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    widget.showCreateMissionListenable.removeListener(_onCreateModeChanged);
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMoreMissions();
      }
    }
  }

  Future<void> _loadMoreMissions() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final newMissions = await _repo.fetchMissionsList(
        page: _currentPage + 1,
        pageSize: 10,
      );

      if (!mounted) return;

      setState(() {
        _currentPage++;
        _missions.addAll(newMissions);
        _isLoadingMore = false;
        _hasMore = newMissions.length >= 10;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _onCreateModeChanged() {
    if (!widget.showCreateMissionListenable.value) {
      _loadMissions();
    }
  }

  Future<void> _loadMissions() async {
    // SÉCURITÉ : Éviter les fetchs concurrents (et non pas l'état UI initial)
    if (_isFetching) {
      _logger.d('_loadMissions: Déjà en cours, skip');
      return;
    }
    _isFetching = true;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    _logger.d('Auth check: isAuthenticated=${auth.isAuthenticated}');

    if (!auth.isAuthenticated) {
      _logger.d('Utilisateur non authentifié, skip missions load');
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
      _currentPage = 1;
      _hasMore = true;
    });

    // Initialiser le cache si nécessaire
    if (!_cacheService.isInitialized) {
      try {
        await _cacheService.init();
      } catch (e) {
        // Continuer même si le cache échoue
      }
    }

    // 1. Charger depuis le cache d'abord (Cache-First)
    _loadMissionsFromCache();

    // 2. Charger depuis l'API en arrière-plan
    _loadMissionsFromApi();
  }

  void _loadMissionsFromCache() {
    try {
      final cachedMissionsJson =
          _cacheService.getCachedJsonResponse('missions_list');
      if (cachedMissionsJson != null &&
          _cacheService.isJsonCacheValid('missions_list')) {
        final cachedData = jsonDecode(cachedMissionsJson);
        if (cachedData is Map && cachedData['data'] is List) {
          final missionsList = (cachedData['data'] as List)
              .map((e) => MissionModel.fromJson(e as Map<String, dynamic>))
              .toList();
          if (mounted) {
            setState(() {
              _missions = missionsList;
              _loading = false;
            });
            _logger
                .d('Missions chargées depuis le cache: ${missionsList.length}');
          }
        }
      }
    } catch (e) {
      _logger.w('Erreur lecture cache missions: $e');
    }
  }

  Future<void> _loadMissionsFromApi() async {
    _logger.d('Chargement des missions depuis l\'API...');

    try {
      final missions = await _repo.fetchMissionsList(
        page: 1,
        pageSize: 10,
      );
      _logger.d('Missions reçues: ${missions.length}');

      // Désactivé: Vérifier les missions terminées non notées
      // Le modal ne devrait s'afficher que lors d'une action utilisateur spécifique
      // _checkForUnratedMissions(missions);

      // Mettre à jour le cache
      try {
        await _cacheService.cacheJsonResponse(
            'missions_list',
            jsonEncode({
              'data': missions.map((m) => m.toJson()).toList(),
            }));
        _logger.d('Missions mises en cache');
      } catch (e) {
        _logger.w('Erreur mise en cache missions: $e');
      }

      if (!mounted) return;
      setState(() {
        _missions = missions;
        _loading = false;
        _hasMore = missions.length >= 10;
        _error = null;
      });
    } catch (e, st) {
      _logger.e('Erreur chargement missions', error: e, stackTrace: st);

      if (!mounted) return;
      setState(() {
        _error = "Erreur de connexion aux missions: ${e.toString()}";
        _loading = false;
        _missions = [];
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

        // Afficher un indicateur de chargement initial si nécessaire
        if (_loading && _missions.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: SkeletonLoading.list(itemCount: 3),
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
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
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
              if (_error != null)
                SliverFillRemaining(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    child: _buildErrorState(),
                  ),
                )
              else if (filtered.isEmpty)
                SliverFillRemaining(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    child: _buildEmptyState(),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == filtered.length) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFFFD400),
                            ),
                          ),
                        );
                      }

                      final mission = filtered[index];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                        child: MissionCard(
                          title: mission.title,
                          type: mission.category ?? 'Service',
                          status: mission.statusDisplay,
                          time: mission.timeAgo,
                          price: mission.price,
                          heroTag: 'mission_${mission.id}',
                          missionStatus: mission.status,
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.missionDetail,
                            arguments: {'missionId': mission.id},
                          ),
                        ),
                      );
                    },
                    childCount: filtered.length + (_isLoadingMore ? 1 : 0),
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
            Icon(Icons.assignment_late_outlined,
                size: 48, color: Colors.black54),
            SizedBox(height: 12),
            Text('Aucune mission trouvée',
                style: TextStyle(color: Colors.black87, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    // Check if error is related to authentication
    final isAuthError = _error?.toLowerCase().contains('connect') == true ||
        _error?.toLowerCase().contains('auth') == true ||
        _error?.toLowerCase().contains('session') == true;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isAuthError ? Icons.lock_outline : Icons.error_outline,
            size: 48,
            color: Colors.red[700],
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: TextStyle(color: Colors.red[700], fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (isAuthError)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              },
              icon: const Icon(Icons.login),
              label: const Text('Se connecter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD400),
                foregroundColor: Colors.black,
              ),
            )
          else
            ElevatedButton(
              onPressed: _loadMissions,
              child: const Text('Réessayer'),
            ),
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
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
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
  final double? price;
  final VoidCallback? onTap;
  final String? heroTag;
  final MissionStatus? missionStatus;

  const MissionCard(
      {super.key,
      required this.title,
      required this.type,
      required this.status,
      required this.time,
      this.price,
      this.onTap,
      this.heroTag,
      this.missionStatus});

  @override
  Widget build(BuildContext context) {
    final cardContent = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Colonne Gauche: Icône de mission
            const Icon(
              Icons.assignment_outlined,
              color: Colors.black54,
              size: 24,
            ),
            const SizedBox(width: 12),
            // Colonne Droite: Toutes les informations
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre (2 lignes max avec ellipsis)
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Ligne 2: Type | Montant
                  Text(
                    '$type | ${price != null ? '${price!.toInt()} FCFA' : ''}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Ligne 3: Date relative et Statut
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        time,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                      _StatusBadge(
                          status: status, missionStatus: missionStatus),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (heroTag != null) {
      return Hero(
        tag: heroTag!,
        child: Material(
          color: Colors.transparent,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final MissionStatus? missionStatus;
  const _StatusBadge({required this.status, this.missionStatus});

  @override
  Widget build(BuildContext context) {
    // Use dynamic colors from MissionStatus if available
    Color bg = missionStatus?.badgeBackgroundColor ?? Colors.green[50]!;
    Color fg = missionStatus?.badgeColor ?? Colors.green[800]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 10),
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
              "Déléguez vos tâches\net vivez autrement",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                  color: Colors.black),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
                color: Colors.black, shape: BoxShape.circle),
            child: const Icon(Icons.hourglass_bottom, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
