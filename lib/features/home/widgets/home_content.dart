import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../widgets/main_wrapper.dart';

/// Bloc corps de page d’accueil (carrousel auto, missions, suggestions, litige).
/// Contient le [PageController], le métronome pour le slider et la liste des slides.
///
/// À placer sous un défilement ou un corps de [Scaffold] parent (voir [HomeScreen]).
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final PageController _pageController = PageController();
  Timer? _heroTimer;

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
        const SizedBox(height: 8),
        const WelcomeHeader(),
        const SizedBox(height: 25),
        HeroCarouselStrip(
          pageController: _pageController,
          assetPaths: _heroAssets,
        ),
        const SizedBox(height: 25),
        PrimaryCreateMissionPanel(
          onPressed: () {
            if (shell != null) {
              shell.setIndex(1);
              shell.openCreateMission();
              return;
            }
            // Fallback si le contenu est utilisé hors shell.
            Navigator.pushNamed(context, AppRoutes.createMission);
          },
        ),
        SectionTitleStrip(
          title: 'Missions en cours',
          onSeeAllPressed: shell == null ? null : () => shell.setIndex(1),
        ),
        const SizedBox(height: 12),
        const OngoingMissionStrip(),
        const SizedBox(height: 25),
        SectionTitleStrip(
          title: 'Suggestions d\'agents',
          showSeeAll: true,
          onSeeAllPressed: shell == null ? null : () => shell.setIndex(2),
        ),
        const SizedBox(height: 12),
        const AgentSuggestionSlider(),
        const SizedBox(height: 25),
        const SectionTitleStrip(title: 'Historique rapide'),
        const SizedBox(height: 10),
        const QuickHistoryEntries(),
        const SizedBox(height: 25),
        const ReportLitigeCardPanel(),
        SizedBox(height: bottomReserve),
      ],
    );
  }
}

/// En-tête de salutation : texte utilisateur fictif mais texte métier préservé.
class WelcomeHeader extends StatelessWidget {
  const WelcomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bonjour, Thomas !',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          Text(
            'Où pouvons-nous vous aider aujourd’hui ?',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
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
      height: 180,
      child: PageView.builder(
        controller: pageController,
        itemBuilder: (context, index) {
          return HeroCarouselSlide(assetPath: assetPaths[index % assetPaths.length]);
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
        color: Colors.grey[200],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            assetPath,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) {
              return Container(
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, color: Colors.grey, size: 40),
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
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          if (showSeeAll)
            TextButton(
              onPressed: onSeeAllPressed,
              child: const Text(
                'Voir tous',
                style: TextStyle(color: Color(0xFF715D00), fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}

/// Carte «Signaler un problème» en pied de page d’accueil.
class ReportLitigeCardPanel extends StatelessWidget {
  const ReportLitigeCardPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1C1C),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: Color(0xFFFFD400), shape: BoxShape.circle),
                  child: const Icon(Icons.gpp_maybe_rounded, color: Colors.black),
                ),
                const SizedBox(width: 15),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Signaler un problème',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Un souci ? Nous intervenons.',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.litige),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD400),
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                elevation: 0,
              ),
              child: const Text('OUVRIR UN LITIGE', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Liste horizontale des profils d'agents certifiés.
class AgentSuggestionSlider extends StatefulWidget {
  const AgentSuggestionSlider({super.key});

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
    // Demande: slider qui défile de droite vers gauche en boucle sans arrêt.
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 1400), _onTick);
  }

  void _onTick(Timer timer) {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
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
    // Simulation de données agents (à remplacer plus tard par une API)
    final List<Map<String, String>> agents = [
      {
        'name': 'Marc-Antoine',
        'role': 'Polyvalent',
        'image': 'assets/images/avatar/agent1.jpg',
      },
      {
        'name': 'Pauline C.',
        'role': 'Conciergerie & Courses',
        'image': 'assets/images/avatar/agent2.avif',
      },
      {
        'name': 'Thomas L.',
        'role': 'Assistant de maison',
        'image': 'assets/images/avatar/agent3.png',
      },
    ];

    return SizedBox(
      height: 200, // Hauteur ajustée pour les cartes agents
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: agents.length * 20,
        itemBuilder: (context, index) {
          final agent = agents[index % agents.length];
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
                  radius: 40,
                  backgroundColor: Colors.grey[200],
                  child: ClipOval(
                    child: Image.asset(
                      imagePath,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return const Icon(Icons.person, color: Colors.black54, size: 40);
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
                  child: const Icon(
                    Icons.verified,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              role,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            // Petit bouton profil
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD400),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Voir Profil',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
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
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Liste horizontale de cartes mission en cours.
class OngoingMissionStrip extends StatelessWidget {
  const OngoingMissionStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 85,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: const [
          OngoingMissionCard(
            title: 'Banque Nationale',
            agentName: 'Marc',
            statusLabel: 'En route',
          ),
          OngoingMissionCard(
            title: 'Poste Centrale',
            agentName: 'Julie',
            statusLabel: 'Sur place',
          ),
        ],
      ),
    );
  }
}

/// Carte mission horizontale unique.
class OngoingMissionCard extends StatelessWidget {
  final String title;
  final String agentName;
  final String statusLabel;

  const OngoingMissionCard({
    super.key,
    required this.title,
    required this.agentName,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance_rounded, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('Agent: $agentName', style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD400).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusLabel,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.brown),
            ),
          ),
        ],
      ),
    );
  }
}

/// Historique court : deux entrées factices pour le wireframe.
class QuickHistoryEntries extends StatelessWidget {
  const QuickHistoryEntries({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        HistoryEntryRow(title: 'Bureau de Poste', dateLine: 'Hier, 14:30', priceLabel: '12,50€'),
        HistoryEntryRow(title: 'Billetterie Concert', dateLine: '12 Oct, 10:15', priceLabel: '25,00€'),
        HistoryEntryRow(title: 'Banque Nationale', dateLine: 'Hier, 14:30', priceLabel: '12,50€'),
      ],
    );
  }
}

/// Ligne d’historique compacte.
class HistoryEntryRow extends StatelessWidget {
  final String title;
  final String dateLine;
  final String priceLabel;

  const HistoryEntryRow({
    super.key,
    required this.title,
    required this.dateLine,
    required this.priceLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFF3F3F3),
                child: Icon(Icons.history, color: Colors.grey, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(dateLine, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ],
          ),
          Text(priceLabel, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
