import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

import 'package:fonaco/core/providers/mission_provider.dart';
import 'package:fonaco/core/models/mission_model.dart';
import 'package:fonaco/core/routes/app_routes.dart';
import 'package:fonaco/core/providers/auth_provider.dart';
import 'package:fonaco/core/services/cache_service.dart';
import 'package:fonaco/core/widgets/skeleton_loading.dart';
import 'package:fonaco/widgets/main_wrapper.dart';
import 'mission_repository.dart';
import 'screens/create_mission_screen.dart';
import 'package:go_router/go_router.dart';

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
  String _filter = 'all'; // 'all', 'ongoing', 'completed', 'cancelled', 'archived'
  String _searchQuery = '';
  Set<String> _archivedIds = {};
  int _createMissionSession = 0;

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
    Future.microtask(() async {
      await _loadArchivedIds();
      await _loadMissions();
    });
    // Écouter les changements pour rafraîchir la liste quand on quitte le mode création
    widget.showCreateMissionListenable.addListener(_onCreateModeChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MissionProvider>().addListener(_onMissionProviderChanged);
      }
    });
  }

  void _onMissionProviderChanged() {
    if (!mounted) return;
    _loadMissions();
  }

  @override
  void dispose() {
    try {
      context.read<MissionProvider>().removeListener(_onMissionProviderChanged);
    } catch (_) {}
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
      final result = await _repo.fetchMissionsPage(
        page: _currentPage + 1,
        pageSize: 10,
      );

      if (!mounted) return;

      setState(() {
        _currentPage++;
        _missions.addAll(result.missions);
        _isLoadingMore = false;
        _hasMore = result.hasMore;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadArchivedIds() async {
    final userId =
        Provider.of<AuthProvider>(context, listen: false).currentUser?.id ?? '';
    if (userId.isEmpty) return;

    if (!_cacheService.isInitialized) {
      try {
        await _cacheService.init();
      } catch (e) {
        _logger.w('Cache non initialisé pour archivage: $e');
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      _archivedIds = _cacheService.getArchivedMissionIds(userId).toSet();
    });
  }

  Future<void> _archiveMission(String missionId) async {
    final userId =
        Provider.of<AuthProvider>(context, listen: false).currentUser?.id ?? '';
    if (userId.isEmpty) return;

    final ok = await _cacheService.archiveMission(userId, missionId);
    if (!mounted) return;

    if (ok) {
      setState(() => _archivedIds.add(missionId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mission archivée')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'archiver la mission. Réessayez.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _unarchiveMission(String missionId) async {
    final userId =
        Provider.of<AuthProvider>(context, listen: false).currentUser?.id ?? '';
    if (userId.isEmpty) return;

    final ok = await _cacheService.unarchiveMission(userId, missionId);
    if (!mounted) return;

    if (ok) {
      setState(() => _archivedIds.remove(missionId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mission retirée des archives')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de désarchiver. Réessayez.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onCreateModeChanged() {
    if (!widget.showCreateMissionListenable.value) {
      setState(() => _createMissionSession++);
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
      final result = await _repo.fetchMissionsPage(
        page: 1,
        pageSize: 10,
      );
      final missions = result.missions;
      _logger
          .d('Missions reçues: ${missions.length}, hasMore: ${result.hasMore}');

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
        _hasMore = result.hasMore;
        _error = null;
      });
      await _loadArchivedIds();
    } catch (e, st) {
      _logger.e('Erreur chargement missions', error: e, stackTrace: st);

      if (!mounted) return;
      setState(() {
        _error = "Erreur de connexion aux missions: ${e.toString()}";
        _loading = false;
      });
    } finally {
      _isFetching = false;
    }
  }

  bool _isArchived(String id) => _archivedIds.contains(id);

  /// Logique de filtrage des missions
  List<MissionModel> get _filteredMissions {
    if (_filter == 'archived') {
      return _missions.where((m) => _isArchived(m.id)).toList();
    }

    final visible = _missions.where((m) => !_isArchived(m.id));

    switch (_filter) {
      case 'ongoing':
        return visible
            .where((m) =>
                m.status == MissionStatus.PENDING ||
                m.status == MissionStatus.ACCEPTED ||
                m.status == MissionStatus.ON_THE_WAY ||
                m.status == MissionStatus.ARRIVED ||
                m.status == MissionStatus.IN_PROGRESS ||
                m.status == MissionStatus.IN_PROGRESS_REVIEW)
            .toList();
      case 'completed':
        return visible
            .where((m) => m.status == MissionStatus.COMPLETED)
            .toList();
      case 'cancelled':
        return visible
            .where((m) =>
                m.status == MissionStatus.CANCELLED ||
                m.status == MissionStatus.DISPUTED)
            .toList();
      default:
        return visible.toList();
    }
  }

  List<MissionModel> _prioritizeReviewMissions(List<MissionModel> missions) {
    final review = missions
        .where((m) => m.status == MissionStatus.IN_PROGRESS_REVIEW)
        .toList();
    final others = missions
        .where((m) => m.status != MissionStatus.IN_PROGRESS_REVIEW)
        .toList();
    return [...review, ...others];
  }

  List<MissionModel> get _displayMissions {
    final base = _prioritizeReviewMissions(_filteredMissions);
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return base;
    return base.where((m) {
      final title = m.title.toLowerCase();
      final desc = m.description.toLowerCase();
      final cat = (m.category ?? '').toLowerCase();
      final addr = (m.address ?? '').toLowerCase();
      return title.contains(q) ||
          desc.contains(q) ||
          cat.contains(q) ||
          addr.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.showCreateMissionListenable,
      builder: (context, isCreating, _) {
        if (isCreating) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: CreateMissionScreen(
              key: ValueKey('create-mission-$_createMissionSession'),
            ),
          );
        }

        // Afficher un indicateur de chargement initial si nécessaire
        if (_loading && _missions.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: SkeletonLoading.list(itemCount: 3),
          );
        }

        final filtered = _displayMissions;

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
                            _CategoryChip(
                              label: "Archivées",
                              isActive: _filter == 'archived',
                              onTap: () =>
                                  setState(() => _filter = 'archived'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                          hintText: 'Rechercher une mission…',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: Colors.grey.shade600,
                            size: 22,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE8E8E8),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE8E8E8),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFFFD400),
                              width: 1.5,
                            ),
                          ),
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
                          showArchiveAction: _filter != 'archived',
                          showUnarchiveAction: _filter == 'archived',
                          onArchive: () => _archiveMission(mission.id),
                          onUnarchive: () => _unarchiveMission(mission.id),
                          onTap: () => context.push(AppRoutes.missionDetail, extra: {'missionId': mission.id},
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
                context.replace(AppRoutes.login);
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
  final bool showArchiveAction;
  final bool showUnarchiveAction;
  final VoidCallback? onArchive;
  final VoidCallback? onUnarchive;

  const MissionCard(
      {super.key,
      required this.title,
      required this.type,
      required this.status,
      required this.time,
      this.price,
      this.onTap,
      this.heroTag,
      this.missionStatus,
      this.showArchiveAction = false,
      this.showUnarchiveAction = false,
      this.onArchive,
      this.onUnarchive});

  @override
  Widget build(BuildContext context) {
    final hasArchiveAction = showArchiveAction && onArchive != null;
    final hasUnarchiveAction = showUnarchiveAction && onUnarchive != null;
    final needsUrgentValidation =
        missionStatus == MissionStatus.IN_PROGRESS_REVIEW;

    Widget cardBody = Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: needsUrgentValidation
            ? Border.all(color: const Color(0xFFE65100), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: needsUrgentValidation
                ? const Color(0xFFE65100).withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: needsUrgentValidation ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (needsUrgentValidation) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFE65100), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Action requise : validation urgente',
                      style: TextStyle(
                        color: Color(0xFFE65100),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
          const Icon(
            Icons.assignment_outlined,
            color: Colors.black54,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    right: (hasArchiveAction || hasUnarchiveAction) ? 28 : 0,
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$type | ${price != null ? '${price!.toInt()} FCFA' : ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      time,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                    _StatusBadge(
                      status: status,
                      missionStatus: missionStatus,
                    ),
                  ],
                ),
              ],
            ),
          ),
            ],
          ),
        ],
      ),
    );

    Widget cardContent = Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: cardBody,
        ),
        if (hasArchiveAction)
          Positioned(
            top: 4,
            right: 4,
            child: _MissionArchiveButton(
              icon: Icons.archive_outlined,
              tooltip: 'Archiver',
              onPressed: onArchive!,
            ),
          ),
        if (hasUnarchiveAction)
          Positioned(
            top: 4,
            right: 4,
            child: _MissionArchiveButton(
              icon: Icons.unarchive_outlined,
              tooltip: 'Retirer des archives',
              onPressed: onUnarchive!,
            ),
          ),
      ],
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

class _MissionArchiveButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _MissionArchiveButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(10),
      elevation: 1,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Icon(
              icon,
              size: 24,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
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
