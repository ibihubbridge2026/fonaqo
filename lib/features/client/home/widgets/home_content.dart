import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fonaco/core/models/mission_model.dart';
import 'package:fonaco/core/providers/auth_provider.dart';
import 'package:fonaco/core/routes/app_routes.dart';
import 'package:fonaco/widgets/main_wrapper.dart';
import 'package:provider/provider.dart';

import 'package:fonaco/features/client/missions/mission_repository.dart';

/// Constante pour la couleur des liens "Voir tous"
/// Peut être changée en Colors.grey[700] pour un look plus discret
final Color _seeAllColor = Colors.grey[700]!;

/// Bloc corps de page d'accueil (carrousel, missions API, suggestions agents).
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final PageController _pageController = PageController();
  Timer? _heroTimer;
  final MissionRepository _missionRepo = MissionRepository();

  List<MissionModel> _missions = [];
  List<Map<String, dynamic>> _suggestedAgents = [];
  bool _dashLoading = true;
  String? _dashError;

  /// Chemins relatifs aux visuels du carrousel héros (boucle automatique sans fin logique index).
  final List<String> _heroAssets = const [
    'assets/images/hero/img-1.jpeg',
    'assets/images/hero/img-2.jpg',
    'assets/images/hero/img-3.jpg',
  ];

  int _logicalHeroPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _heroTimer = Timer.periodic(const Duration(seconds: 4), _onHeroTick);
    // Lazy loading: delay data loading until after first frame
    Future.microtask(() => _loadDashboard());
  }

  @override
  void didUpdateWidget(HomeContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recharger les données lorsque le widget est mis à jour (retour sur la page)
    _loadDashboard();
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
    setState(() {
      _dashLoading = true;
      _dashError = null;
    });
    try {
      final missions = await _missionRepo.fetchMissionsList();

      // Pour l'instant, nous n'utilisons pas la localisation
      // TODO: Ajouter la localisation à UserModel et utiliser les coordonnées utilisateur
      final agents = await _missionRepo.fetchAgentSuggestions();

      if (!mounted) return;
      setState(() {
        _missions = missions;
        _suggestedAgents = agents;
        _dashLoading = false;
      });
    } catch (e) {
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

  List<MissionModel> _ongoingMissions() {
    final ongoing = _missions
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
    final bottomReserve = MediaQuery.paddingOf(context).bottom + 12;
    final shell = MainShellScope.maybeOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const WelcomeHeader(),
        const SizedBox(height: 25),
        HeroCarouselStrip(
          pageController: _pageController,
          assetPaths: _heroAssets,
        ),
        const SizedBox(height: 25),
        PrimaryCreateMissionPanel(
          onPressed: () async {
            if (shell != null) {
              // Naviguer vers l'onglet missions et attendre un retour avec valeur true
              shell.setIndex(1);
              await Future.delayed(const Duration(milliseconds: 100));
              // La logique de rafraîchissement sera gérée par didUpdateWidget
              // quand l'utilisateur reviendra sur cet onglet
            } else {
              // Fallback si le contenu est utilisé hors shell.
              Navigator.pushNamed(context, AppRoutes.missionDetail);
            }
          },
        ),
        SectionTitleStrip(
          title: 'Missions en cours',
          onSeeAllPressed: shell == null ? null : () => shell.setIndex(1),
        ),
        const SizedBox(height: 12),
        if (_dashLoading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            child: Center(child: CircularProgressIndicator()),
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
          OngoingMissionStrip(missions: _ongoingMissions()),
        ],
        const SizedBox(height: 25),
        SectionTitleStrip(
          title: 'Suggestions d\'agents',
          showSeeAll: true,
          onSeeAllPressed: shell == null ? null : () => shell.setIndex(2),
        ),
        const SizedBox(height: 12),
        if (_dashLoading)
          const SizedBox(height: 8)
        else
          AgentSuggestionSlider(agents: _suggestedAgents),
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
                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
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

/// Bouton primaire création de mission.
class PrimaryCreateMissionPanel extends StatelessWidget {
  /// Callback déclenchée lorsque l’utilisateur veut créer une mission.
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

/// Rangée titre + lien «Voir tous» optionnel.
class SectionTitleStrip extends StatelessWidget {
  final String title;
  final bool showSeeAll;
  final VoidCallback? onSeeAllPressed;

  const SectionTitleStrip({
    super.key,
    required this.title,
    this.showSeeAll = true,
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
                    'Voir tous',
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
  const AvailableMissionsPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
          minHeight: 100, maxHeight: 140), // Flexible height range
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
          const Text(
            'Découvrez les missions près de chez vous',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              children: List.generate(4, (index) {
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
                        'Mission ${index + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '2.5 km • 50€/h',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/missions-available'),
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
          color: Colors.red.withOpacity(0.05),
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
                border: Border.all(color: Colors.black.withOpacity(0.1)),
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
                onPressed: () => Navigator.pushNamed(context, AppRoutes.litige),
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

  const AgentSuggestionSlider({super.key, required this.agents});

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
      const Duration(milliseconds: 1400),
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

    final display = <Map<String, String>>[];
    for (final raw in rows) {
      final fn = raw['first_name']?.toString() ?? '';
      final ln = raw['last_name']?.toString() ?? '';
      final un = raw['username']?.toString() ?? '';
      final name =
          ('$fn $ln').trim().isEmpty ? un : '${fn.trim()} ${ln.trim()}'.trim();
      display.add({
        'name': name.isEmpty ? 'Agent' : name,
        'role': raw['specialty']?.toString() ?? 'Agent terrain',
        'image': 'assets/images/avatar/user.png',
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
          return AgentCard(
            name: agent['name']!,
            role: agent['role']!,
            imagePath: agent['image']!,
          );
        },
      ),
    );
  }
}

/// Carte individuelle d'un agent avec badge de certification.
class AgentCard extends StatelessWidget {
  final String name;
  final String role;
  final String imagePath;

  const AgentCard({
    super.key,
    required this.name,
    required this.role,
    required this.imagePath,
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
            color: Colors.black.withOpacity(0.05),
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
                  child: Image.asset(
                    imagePath,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return const Icon(
                        Icons.person,
                        color: Colors.black54,
                        size: 32,
                      );
                    },
                  ),
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
          Container(
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
        ],
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
            color: Colors.black.withOpacity(0.04),
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
        Navigator.pushNamed(
          context,
          AppRoutes.missionDetail,
          arguments: {'missionId': missionId},
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
              color: Colors.black.withOpacity(0.04),
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
                              Colors.grey.withOpacity(0.2),
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
              Navigator.pushNamed(
                context,
                AppRoutes.missionDetail,
                arguments: {'missionId': m.id},
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
                        Colors.grey.withOpacity(0.2),
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
