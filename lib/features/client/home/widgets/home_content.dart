import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:fonaco/core/models/mission_model.dart';
import 'package:fonaco/core/providers/auth_provider.dart';
import 'package:fonaco/core/providers/favorites_provider.dart';
import 'package:fonaco/core/providers/mission_provider.dart';
import 'package:fonaco/core/routes/app_routes.dart';
import 'package:fonaco/core/services/cache_service.dart';
import 'package:fonaco/core/widgets/agent_avatar.dart';
import 'package:fonaco/core/widgets/skeleton_loading.dart';
import 'package:fonaco/widgets/main_wrapper.dart';
import 'package:provider/provider.dart';

import 'package:fonaco/features/client/missions/mission_repository.dart';
import 'package:fonaco/features/client/screens/client_agent_profile_screen.dart';
import 'package:go_router/go_router.dart';

/// Constante pour la couleur des liens "Voir tous"
/// Peut être changée en Colors.grey[700] pour un look plus discret
final Color _seeAllColor = Colors.grey[700]!;

/// Bloc corps de page d'accueil (carrousel, missions API, suggestions agents).
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final PageController _pageController = PageController();
  Timer? _heroTimer;
  final MissionRepository _missionRepo = MissionRepository();
  final CacheService _cacheService = CacheService();
  final Logger _logger = Logger();

  List<MissionModel> _missions = [];
  List<Map<String, dynamic>> _suggestedAgents = [];
  bool _dashLoading = true;
  String? _dashError;

  int _logicalHeroPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _heroTimer = Timer.periodic(const Duration(seconds: 4), _onHeroTick);
    // Lazy loading: delay data loading until after first frame
    Future.microtask(() => _loadDashboard());
    // Initialiser le provider de favoris avec l'userId
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final favoritesProvider =
        Provider.of<FavoritesProvider>(context, listen: false);
    if (auth.currentUser?.id != null) {
      favoritesProvider.init(auth.currentUser!.id);
    }
  }

  void _toggleFavoriteAgent(String agentId) {
    final favoritesProvider =
        Provider.of<FavoritesProvider>(context, listen: false);
    favoritesProvider.toggleFavorite(agentId);
  }

  Future<void> _loadDashboard() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      if (mounted) {
        setState(() {
          _dashLoading = false;
          _missions = [];
          _suggestedAgents = [];
        });
      }
      return;
    }

    // Initialiser le cache si nécessaire
    if (!_cacheService.isInitialized) {
      try {
        await _cacheService.init();
      } catch (e) {
        // Continuer même si le cache échoue
      }
    }

    // 1. Charger depuis le cache d'abord (Cache-First)
    _loadFromCache();

    // 2. Charger depuis l'API en arrière-plan
    _loadFromApi();
  }

  void _loadFromCache() {
    try {
      _logger.d('Chargement depuis le cache...');
      // Charger les missions depuis le cache
      final cachedMissionsJson =
          _cacheService.getCachedJsonResponse('dashboard_missions');
      if (cachedMissionsJson != null &&
          _cacheService.isJsonCacheValid('dashboard_missions', maxAgeMinutes: 2)) {
        final cachedData = jsonDecode(cachedMissionsJson);
        if (cachedData is Map && cachedData['data'] is List) {
          final missionsList = (cachedData['data'] as List)
              .map((e) => MissionModel.fromJson(e as Map<String, dynamic>))
              .toList();
          if (mounted) {
            setState(() {
              _missions = missionsList;
              // Ne pas mettre _dashLoading à false ici - attendre l'API ou un délai minimum
            });
            _logger
                .d('${missionsList.length} missions chargées depuis le cache');
          }
        }
      } else {
        _logger.w('Cache missions vide ou invalide');
      }

      // Charger les agents depuis le cache
      final cachedAgentsJson =
          _cacheService.getCachedJsonResponse('dashboard_agents');
      if (cachedAgentsJson != null &&
          _cacheService.isJsonCacheValid('dashboard_agents', maxAgeMinutes: 2)) {
        final cachedData = jsonDecode(cachedAgentsJson);
        if (cachedData is Map && cachedData['data'] is List) {
          final agentsList = (cachedData['data'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          if (mounted) {
            setState(() {
              _suggestedAgents = agentsList;
            });
            _logger.d('${agentsList.length} agents chargés depuis le cache');
          }
        }
      } else {
        _logger.w('Cache agents vide ou invalide');
      }
    } catch (e) {
      _logger.e('Erreur chargement cache', error: e);
      // Erreur de cache, continuer avec API
    }
  }

  Future<void> _loadFromApi() async {
    final startTime = DateTime.now();
    try {
      final missions = await _missionRepo.fetchMissionsList();

      _logger.d('Missions reçues depuis API: ${missions.length}');
      for (var m in missions) {
        _logger.d('  - ${m.title} (status: ${m.status})');
      }

      // Pour l'instant, nous n'utilisons pas la localisation
      // TODO: Ajouter la localisation à UserModel et utiliser les coordonnées utilisateur
      final agents = await _missionRepo.fetchAgentSuggestions();

      _logger.d('Agents reçus depuis API: ${agents.length}');

      // Mettre à jour le cache
      try {
        await _cacheService.cacheJsonResponse(
            'dashboard_missions',
            jsonEncode({
              'data': missions.map((m) => m.toJson()).toList(),
            }));
        await _cacheService.cacheJsonResponse(
            'dashboard_agents',
            jsonEncode({
              'data': agents,
            }));
      } catch (e) {
        // Erreur de cache, ignorer
      }

      // Attendre au moins 200ms pour que l'utilisateur voie l'indicateur de chargement
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      if (elapsed < 200) {
        await Future.delayed(Duration(milliseconds: 200 - elapsed));
      }

      if (!mounted) return;
      setState(() {
        _missions = missions;
        _suggestedAgents = agents;
        _dashLoading = false;
        _dashError = null;
      });
    } catch (e) {
      _logger.e('Erreur chargement API', error: e);
      if (!mounted) return;
      setState(() {
        _dashError = e.toString();
        _dashLoading = false;
      });
    }
  }

  void _onHeroTick(Timer timer) {
    if (!_pageController.hasClients) return;
    _logicalHeroPageIndex++;
    _pageController.animateToPage(
      _logicalHeroPageIndex,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    );
  }

  List<MissionModel> _ongoingMissionsFrom(List<MissionModel> source) {
    final ongoing = source
        .where(
          (m) =>
              m.status == MissionStatus.PENDING ||
              m.status == MissionStatus.ACCEPTED ||
              m.status == MissionStatus.ON_THE_WAY ||
              m.status == MissionStatus.ARRIVED ||
              m.status == MissionStatus.IN_PROGRESS,
        )
        .toList();
    // Sort by createdAt desc (most recent first)
    ongoing.sort((a, b) {
      if (a.createdAt == null && b.createdAt == null) return 0;
      if (a.createdAt == null) return 1;
      if (b.createdAt == null) return -1;
      return b.createdAt!.compareTo(a.createdAt!);
    });
    return ongoing.take(8).toList();
  }

  List<MissionModel> _historyMissions() {
    return _missions
        .where((m) =>
            m.status == MissionStatus.COMPLETED ||
            m.status == MissionStatus.CANCELLED)
        .take(4)
        .toList()
      ..sort((a, b) => (b.createdAt ?? DateTime.now())
          .compareTo(a.createdAt ?? DateTime.now()));
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bottomReserve = MediaQuery.paddingOf(context).bottom + 12;
    final shell = MainShellScope.maybeOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const WelcomeHeader(),
        const SizedBox(height: 25),
        // Old hero slider commented out - replaced with InfoSlider
        // HeroCarouselStrip(
        //   pageController: _pageController,
        //   assetPaths: _heroAssets,
        // ),
        const InfoSlider(),
        const SizedBox(height: 16),
        PrimaryCreateMissionPanel(
          onPressed: () async {
            if (shell != null) {
              shell.setIndex(1);
              shell.openCreateMission();
            }
          },
        ),
        const SizedBox(height: 12),
        // Désactivé temporairement — réactivation prévue prochainement.
        // VocalCreateMissionButton(
        //   onPressed: () {
        //     context.push(AppRoutes.createMissionVocal);
        //   },
        // ),
        SectionTitleStrip(
          title: 'Missions en cours',
          onSeeAllPressed: shell == null ? null : () => shell.setIndex(1),
        ),
        const SizedBox(height: 12),
        if (_dashLoading)
          Container(
            height: 100,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: SkeletonLoading.dashboardCard(),
          )
        else ...[
          if (_dashError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _dashError!,
                style: TextStyle(color: Colors.red[700], fontSize: 13),
              ),
            ),
          Consumer<MissionProvider>(
            builder: (context, missionProvider, _) {
              final source = missionProvider.missions.isNotEmpty
                  ? missionProvider.missions
                  : _missions;
              return OngoingMissionStrip(
                missions: _ongoingMissionsFrom(source),
              );
            },
          ),
        ],
        const SizedBox(height: 25),
        SectionTitleStrip(
          title: 'Suggestions d\'agents',
          showSeeAll: true,
          seeAllText: 'Voir mes favoris',
          onSeeAllPressed: shell == null
              ? null
              : () {
                  context.push(AppRoutes.favoriteAgents);
                },
        ),
        const SizedBox(height: 12),
        if (_dashLoading)
          const SizedBox(height: 8)
        else
          AgentSuggestionSlider(
            agents: _suggestedAgents,
            favoriteAgentIds:
                Provider.of<FavoritesProvider>(context).favoriteAgentIds,
            onToggleFavorite: _toggleFavoriteAgent,
          ),
        const SizedBox(height: 25),
        SectionTitleStrip(
          title: 'Historique rapide',
          onSeeAllPressed: shell == null ? null : () => shell.setIndex(1),
        ),
        const SizedBox(height: 10),
        if (_dashLoading)
          const SizedBox.shrink()
        else
          QuickHistoryEntries(missions: _historyMissions()),
        const SizedBox(height: 25),
        // Section litige uniquement si l'utilisateur a créé au moins une mission
        if (!_dashLoading && _missions.isNotEmpty)
          const ReportLitigeCardPanel(),
        SizedBox(height: bottomReserve),
      ],
    );
  }
}

/// En-tête de salutation dynamique (prénom ou username Django).
class WelcomeHeader extends StatelessWidget {
  const WelcomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final first = auth.currentUser?.firstName?.trim();
        final login = auth.currentUser?.djangoUsername?.trim();
        final greet = (first != null && first.isNotEmpty)
            ? first
            : (login != null && login.isNotEmpty)
                ? login
                : 'Invité';
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bonjour, $greet !',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Où pouvons-nous vous aider aujourd’hui ?',
                style: TextStyle(color: Colors.black87, fontSize: 14),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Bande PageView avec image asset + léger sous-titre; garde une largeur maximale lisible sur tablette.
///
/// [pageController]: contrôleur mutualisé pour l’animation périodique externe au widget.
///
/// [assetPaths]: liste cyclique utilisée modulo l’index de page physique.
class HeroCarouselStrip extends StatelessWidget {
  final PageController pageController;
  final List<String> assetPaths;

  const HeroCarouselStrip({
    super.key,
    required this.pageController,
    required this.assetPaths,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160, // Reduced from 180 for better flexibility
      child: PageView.builder(
        controller: pageController,
        itemBuilder: (context, index) {
          return HeroCarouselSlide(
            assetPath: assetPaths[index % assetPaths.length],
          );
        },
      ),
    );
  }
}

/// Une diapositive avec photo locale recadrée ou placeholder sur erreur d’asset.
class HeroCarouselSlide extends StatelessWidget {
  /// Path publié dans le `pubspec` (voir section `flutter.assets`).
  final String assetPath;

  /// Légende simulée en bas du visuel pour le contexte de la carte.
  final String overlayCaption;

  const HeroCarouselSlide({
    super.key,
    required this.assetPath,
    this.overlayCaption = 'Palais des Congrès, Paris',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey[100],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            assetPath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return Container(
                color: Colors.grey[200],
                child: const Icon(
                  Icons.broken_image,
                  color: Colors.black54,
                  size: 40,
                ),
              );
            },
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7)
                ],
              ),
            ),
            padding: const EdgeInsets.all(20),
            alignment: Alignment.bottomLeft,
            child: Text(
              overlayCaption,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Slider d'informations dynamique avec 3 slides
class InfoSlider extends StatefulWidget {
  const InfoSlider({super.key});

  @override
  State<InfoSlider> createState() => _InfoSliderState();
}

class _InfoSliderState extends State<InfoSlider> {
  final PageController _pageController = PageController();
  Timer? _autoScrollTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), _onTick);
  }

  void _onTick(Timer timer) {
    if (!_pageController.hasClients) return;
    _currentIndex = (_currentIndex + 1) % 3;
    _pageController.animateToPage(
      _currentIndex,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemCount: 3,
        itemBuilder: (context, index) {
          return _InfoSlide(index: index);
        },
      ),
    );
  }
}

class _InfoSlide extends StatelessWidget {
  final int index;

  const _InfoSlide({required this.index});

  @override
  Widget build(BuildContext context) {
    final slides = [
      {
        'icon': Icons.person,
        'message': 'Un agent sera notifié et pourra accepter votre mission.',
        'rightIcon': Icons.verified_user_rounded,
      },
      {
        'icon': Icons.search,
        'message': 'Trackez toutes vos missions en temps réel.',
        'rightIcon': Icons.check_circle,
      },
      {
        'icon': Icons.support_agent,
        'message': 'Une assistance disponible 24/7 pour vos besoins.',
        'rightIcon': Icons.star,
      },
    ];

    final slide = slides[index];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.yellow.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFD400), width: 1),
        ),
        child: Row(
          children: [
            // Icône/Avatar à gauche
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                slide['icon'] as IconData,
                color: const Color(0xFFFFD400),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            // Texte central
            Expanded(
              child: Text(
                slide['message'] as String,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Icône à droite
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD400),
                shape: BoxShape.circle,
              ),
              child: Icon(
                slide['rightIcon'] as IconData,
                color: Colors.black,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bannière de réassurance pour les missions sur le Dashboard (deprecated - use InfoSlider instead)
class MissionReassuranceBanner extends StatelessWidget {
  const MissionReassuranceBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.yellow.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFD400), width: 1),
        ),
        child: Row(
          children: [
            // Image de l'agent avec casquette jaune
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/avatar/user.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return const Icon(
                      Icons.person,
                      color: Colors.grey,
                      size: 24,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Texte central
            const Expanded(
              child: Text(
                'Un agent sera notifié et pourra accepter votre mission.',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Icône bouclier jaune avec check
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD400),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                color: Colors.black,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton primaire création de mission.
class PrimaryCreateMissionPanel extends StatelessWidget {
  /// Callback déclenchée lorsque l'utilisateur veut créer une mission.
  final VoidCallback? onPressed;

  const PrimaryCreateMissionPanel({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add_circle, size: 22),
        label: const Text(
          'CRÉER UNE MISSION',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFD400),
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

/// Bouton création de mission par vocal.
class VocalCreateMissionButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const VocalCreateMissionButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.mic_none_rounded, size: 22),
        label: const Text(
          'Créer par message vocal 🎙️',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.3),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF7C600).withValues(alpha: 0.9),
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 2,
          shadowColor: const Color(0xFFF7C600).withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

/// Rangée titre + lien «Voir tous» optionnel.
class SectionTitleStrip extends StatelessWidget {
  final String title;
  final bool showSeeAll;
  final String? seeAllText;
  final VoidCallback? onSeeAllPressed;

  const SectionTitleStrip({
    super.key,
    required this.title,
    this.showSeeAll = true,
    this.seeAllText,
    this.onSeeAllPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          if (showSeeAll)
            TextButton(
              onPressed: onSeeAllPressed,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    seeAllText ?? 'Voir tous',
                    style: TextStyle(
                      color: _seeAllColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    color: _seeAllColor,
                    size: 16,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Carte «Signaler un problème» en pied de page d’accueil.
/// Aperçu des missions disponibles pour les agents
class AvailableMissionsPreview extends StatelessWidget {
  final List<MissionModel> missions;

  const AvailableMissionsPreview({super.key, required this.missions});

  @override
  Widget build(BuildContext context) {
    final displayMissions = missions.take(4).toList();

    return Container(
      constraints: const BoxConstraints(
          minHeight: 100, maxHeight: 140), // Flexible height range
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(
                Icons.work_outline,
                color: Color(0xFFFFD400),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Missions Disponibles',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF715D00),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (displayMissions.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'Aucune mission disponible',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            )
          else
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                children: displayMissions.map((mission) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: Colors.grey[400],
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          mission.title,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${mission.price.toStringAsFixed(0)} FCFA',
                          style:
                              TextStyle(fontSize: 10, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () =>
                  context.push('/missions-available'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD400),
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Voir toutes les missions',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte «Signaler un problème» en pied de page d'accueil.
class ReportLitigeCardPanel extends StatelessWidget {
  const ReportLitigeCardPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [],
        ),
        child: Row(
          children: [
            // Colonne 1: Icône bouclier
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Colonne 2: Textes
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Signaler un problème',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Un souci ? Nous intervenons.',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Colonne 3: Bouton action
            Container(
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () => context.push(AppRoutes.litige),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Ouvrir',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Liste horizontale des profils d'agents certifiés (données API / seeder).
class AgentSuggestionSlider extends StatefulWidget {
  final List<Map<String, dynamic>> agents;
  final Set<String> favoriteAgentIds;
  final Function(String) onToggleFavorite;

  const AgentSuggestionSlider({
    super.key,
    required this.agents,
    required this.favoriteAgentIds,
    required this.onToggleFavorite,
  });

  @override
  State<AgentSuggestionSlider> createState() => _AgentSuggestionSliderState();
}

class _AgentSuggestionSliderState extends State<AgentSuggestionSlider> {
  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;

  static const double _cardStep = 175;

  @override
  void initState() {
    super.initState();
    _autoScrollTimer = Timer.periodic(
      const Duration(seconds: 4),
      _onTick,
    );
  }

  void _onTick(Timer timer) {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (max <= 0) return;
    final next = _scrollController.offset + _cardStep;

    if (next >= max) {
      _scrollController.jumpTo(0);
      return;
    }

    _scrollController.animateTo(
      next,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rows = widget.agents;
    if (rows.isEmpty) {
      return const SizedBox(
        height: 90, // Reduced from 100 for better flexibility
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Aucun agent suggéré pour le moment.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    final display = <Map<String, dynamic>>[];
    for (final raw in rows) {
      final fn = raw['first_name']?.toString() ?? '';
      final ln = raw['last_name']?.toString() ?? '';
      final un = raw['username']?.toString() ?? '';
      final name =
          ('$fn $ln').trim().isEmpty ? un : '${fn.trim()} ${ln.trim()}'.trim();

      // Extraire les tags d'expertise
      final expertiseTags = (raw['expertise_tags'] as List<dynamic>?)
              ?.map((tag) => tag.toString())
              .toList() ??
          [];

      display.add({
        'name': name.isEmpty ? 'Agent' : name,
        'role': raw['specialty']?.toString() ?? 'Agent terrain',
        'avatar_url': raw['avatar_url']?.toString(),
        'rating': parseAgentRating(
          raw['reliability_score'] ?? raw['rating'],
        ),
        'is_verified': raw['is_verified'] == true,
        'is_online': raw['is_online'] == true,
        'expertise_tags': expertiseTags,
        'agent_id': raw['id']?.toString() ?? '',
      });
    }

    return SizedBox(
      height: 180, // Reduced from 200 for better flexibility
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: display.length * 15,
        itemBuilder: (context, index) {
          final agent = display[index % display.length];
          final agentId = agent['agent_id']?.toString() ?? '';
          return AgentCard(
            name: agent['name']!,
            role: agent['role']!,
            avatarUrl: agent['avatar_url']?.toString(),
            rating: agent['rating'] as double?,
            isVerified: agent['is_verified'] == true,
            isOnline: agent['is_online'] == true,
            expertiseTags: (agent['expertise_tags'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [],
            agentId: agentId,
            isFavorite: widget.favoriteAgentIds.contains(agentId),
            onToggleFavorite: widget.onToggleFavorite,
          );
        },
      ),
    );
  }
}

/// Carte individuelle d'un agent avec badge de certification.
class AgentCard extends StatelessWidget {
  static const String _fallbackAvatarAsset = 'assets/images/avatar/user.png';

  final String name;
  final String role;
  final String? avatarUrl;
  final double? rating;
  final bool isVerified;
  final bool isOnline;
  final List<String> expertiseTags;
  final String agentId;
  final bool isFavorite;
  final Function(String) onToggleFavorite;

  const AgentCard({
    super.key,
    required this.name,
    required this.role,
    this.avatarUrl,
    this.rating,
    this.isVerified = false,
    this.isOnline = false,
    this.expertiseTags = const [],
    required this.agentId,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 15, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.grey[200],
                child: ClipOval(
                  child: _buildAvatarImage(),
                ),
              ),
              // Badge de vérification style "Facebook/Blue Check"
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(2),
                child: const Icon(Icons.verified, color: Colors.blue, size: 16),
              ),
              // Icône favoris
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => onToggleFavorite(agentId),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.grey,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          // Petit bouton profil
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ClientAgentProfileScreen(
                    agentId: agentId,
                    name: name,
                    role: role,
                    avatarUrl: avatarUrl,
                    expertiseTags: expertiseTags,
                    rating: rating,
                    isVerified: isVerified,
                    isOnline: isOnline,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Consultez le Profil',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarImage() {
    final url = avatarUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        placeholder: (_, __) => Image.asset(
          _fallbackAvatarAsset,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
        ),
        errorWidget: (_, __, ___) => Image.asset(
          _fallbackAvatarAsset,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.person,
            color: Colors.black54,
            size: 32,
          ),
        ),
      );
    }

    return Image.asset(
      _fallbackAvatarAsset,
      width: 64,
      height: 64,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(
        Icons.person,
        color: Colors.black54,
        size: 32,
      ),
    );
  }
}

/// Tuile pastel pour suggestion d'agent.
class AgentSuggestionTile extends StatelessWidget {
  final String label;
  final IconData icon;

  const AgentSuggestionTile({
    super.key,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFFFFD400), size: 30),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Liste horizontale de cartes mission en cours (API / seeder).
class OngoingMissionStrip extends StatelessWidget {
  final List<MissionModel> missions;

  const OngoingMissionStrip({super.key, required this.missions});

  @override
  Widget build(BuildContext context) {
    if (missions.isEmpty) {
      return const SizedBox(
        height: 70, // Reduced from 72 for better flexibility
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Aucune mission en cours. Créez-en une ou exécutez le seeder côté serveur.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
        ),
      );
    }

    // Si une seule mission, afficher en pleine largeur
    if (missions.length == 1) {
      final mission = missions.first;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: OngoingMissionCard(
          missionId: mission.id,
          title: mission.title,
          agentName: mission.agentName ?? '—',
          statusLabel: mission.formattedStatus,
          isFullWidth: true,
          missionStatus: mission.status,
        ),
      );
    }

    // Si plusieurs missions, afficher en horizontal
    return SizedBox(
      height: 80, // Reduced from 85 for better flexibility
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          for (final m in missions)
            OngoingMissionCard(
              missionId: m.id,
              title: m.title,
              agentName: m.agentName ?? '—',
              statusLabel: m.formattedStatus,
              isFullWidth: false,
              missionStatus: m.status,
            ),
        ],
      ),
    );
  }
}

/// Carte mission horizontale unique.
class OngoingMissionCard extends StatelessWidget {
  final String missionId;
  final String title;
  final String agentName;
  final String statusLabel;
  final bool isFullWidth;
  final MissionStatus? missionStatus;

  const OngoingMissionCard({
    super.key,
    required this.missionId,
    required this.title,
    required this.agentName,
    required this.statusLabel,
    this.isFullWidth = false,
    this.missionStatus,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.push(AppRoutes.missionDetail, extra: {'missionId': missionId},
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: isFullWidth ? double.infinity : 260,
        margin:
            isFullWidth ? EdgeInsets.zero : const EdgeInsets.only(right: 15),
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
            const Icon(
              Icons.assignment_outlined,
              color: Colors.black54,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Agent: $agentName',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: missionStatus?.badgeBackgroundColor ??
                              Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: missionStatus?.badgeColor ?? Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Historique rapide (missions terminées depuis l'API).
class QuickHistoryEntries extends StatelessWidget {
  final List<MissionModel> missions;

  const QuickHistoryEntries({super.key, required this.missions});

  @override
  Widget build(BuildContext context) {
    if (missions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'Pas encore d\'historique. Les missions terminées apparaîtront ici.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      );
    }
    return Column(
      children: [
        for (final m in missions)
          InkWell(
            onTap: () {
              context.push(AppRoutes.missionDetail, extra: {'missionId': m.id},
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: HistoryEntryRow(
              title: m.title,
              dateLine: m.createdAt != null
                  ? '${m.createdAt!.day}/${m.createdAt!.month}/${m.createdAt!.year}'
                  : '—',
              priceLabel: '${m.price.toStringAsFixed(0)} FCFA',
              status: m.formattedStatus,
              agentName: m.agentName ?? 'Agent assigné',
              missionStatus: m.status,
            ),
          ),
      ],
    );
  }
}

/// Ligne d'historique compacte - Pixel Perfect structure.
class HistoryEntryRow extends StatelessWidget {
  final String title;
  final String dateLine;
  final String priceLabel;
  final String? status;
  final String? agentName;
  final MissionStatus? missionStatus;

  const HistoryEntryRow({
    super.key,
    required this.title,
    required this.dateLine,
    required this.priceLabel,
    this.status,
    this.agentName,
    this.missionStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne 1: Titre avec overflow
          Row(
            children: [
              const Icon(
                Icons.history,
                color: Colors.black54,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 9,
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
            ],
          ),
          const SizedBox(height: 6),
          // Ligne 2: Montant et Statut
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                priceLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
              if (status != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: missionStatus?.badgeBackgroundColor ??
                        Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: missionStatus?.badgeColor ?? Colors.grey,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          // Ligne 3: Agent et Date
          Text(
            '${agentName ?? 'Agent'} • $dateLine',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
