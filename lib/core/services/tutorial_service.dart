import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:flutter/material.dart';

/// Service de gestion des tutoriels guidés (Coach Marks)
/// Permet de créer des visites guidées pour les nouveaux utilisateurs
class TutorialService {
  static final TutorialService _instance = TutorialService._internal();
  factory TutorialService() => _instance;
  TutorialService._internal();

  bool _isInitialized = false;

  // Clés pour stocker si le tutorial a déjà été vu
  static const String _agentTutorialKey = 'agent_tutorial_seen';
  static const String _clientTutorialKey = 'client_tutorial_seen';

  /// Initialisation du service
  void init() {
    _isInitialized = true;
  }

  /// Vérifie si le tutorial agent a déjà été affiché
  Future<bool> hasSeenAgentTutorial() async {
    // À implémenter avec SharedPreferences ou Hive
    return false; // Pour l'instant, on retourne false pour tester
  }

  /// Marque le tutorial agent comme vu
  Future<void> markAgentTutorialAsSeen() async {
    // À implémenter avec SharedPreferences ou Hive
  }

  /// Vérifie si le tutorial client a déjà été affiché
  Future<bool> hasSeenClientTutorial() async {
    return false;
  }

  /// Marque le tutorial client comme vu
  Future<void> markClientTutorialAsSeen() async {
    // À implémenter avec SharedPreferences ou Hive
  }

  /// Crée un Coach Mark pour le Dashboard Agent
  TutorialCoachMark createAgentDashboardTutorial({
    required BuildContext context,
    required List<TargetFocus> targets,
    Function()? onFinish,
  }) {
    return TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black.withValues(alpha: 0.7),
      textSkip: "PASSER",
      textStyleSkip: TextStyle(
        color: Colors.white,
      ),
    );
  }

  /// Génère les cibles pour le dashboard agent
  List<TargetFocus> getAgentDashboardTargets(Map<String, GlobalKey> keys) {
    return [
      TargetFocus(
        identify: "profile_button",
        keyTarget: keys['profileButton']!,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Profil",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Accédez à votre profil et à vos paramètres personnels.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "online_toggle",
        keyTarget: keys['onlineToggle']!,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Statut En Ligne",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Activez/désactivez votre disponibilité pour recevoir de nouvelles missions.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  /// Génère les cibles pour l'écran de création de mission (Client)
  List<TargetFocus> getClientCreateMissionTargets(Map<String, GlobalKey> keys) {
    return [];
  }

  /// Génère les cibles pour l'écran des missions actives (Agent)
  List<TargetFocus> getActiveMissionTargets(Map<String, GlobalKey> keys) {
    return [];
  }

  /// Affiche un popup de bienvenue pour les nouveaux agents
  void showWelcomeDialog({
    required BuildContext context,
    String title = "Bienvenue chez FONAQO !",
    String message =
        "Découvrez comment maximiser vos gains et gérer vos missions efficacement.",
    Function()? onStartTutorial,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Icon(Icons.celebration, color: Color(0xFFFFD400), size: 32),
              SizedBox(width: 12),
              Expanded(child: Text(title)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFFFD400).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb, color: Color(0xFFFFD400)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Le tutoriel dure environ 1 minute",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (onStartTutorial != null) onStartTutorial();
              },
              child: Text(
                "COMMENCER LE TUTORIEL",
                style: TextStyle(
                  color: Color(0xFFFFD400),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                markAgentTutorialAsSeen();
                Navigator.of(context).pop();
              },
              child: Text(
                "PASSER",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Extension pour faciliter la création de GlobalKeys nommées
extension GlobalKeyExtension on Map<String, GlobalKey> {
  void initialize() {
    forEach((key, value) {
      if (value == null) {
        this[key] = GlobalKey();
      }
    });
  }
}
