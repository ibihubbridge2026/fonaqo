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
    required List<FocusTarget> targets,
    Function()? onFinish,
  }) {
    return TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black.withOpacity(0.7),
      textSkip: "PASSER",
      textStyleSkip: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      paddingFocus: 10,
      opacityShadow: 0.8,
      onFinish: () {
        markAgentTutorialAsSeen();
        if (onFinish != null) onFinish();
      },
      onClickTarget: (target) {
        debugPrint('🎯 Cible cliquée: $target');
      },
      onClickTargetWithTapPosition: (target, tapDetails) {
        debugPrint('🎯 Cible cliquée à la position: ${tapDetails.localPosition}');
      },
      onClickOverlay: (target) {
        debugPrint('🎯 Overlay cliqué: $target');
      },
      onHighlight: (target) {
        debugPrint('✨ Cible en surbrillance: $target');
      },
    );
  }

  /// Génère les cibles de focus pour le Dashboard Agent
  List<FocusTarget> getAgentDashboardTargets(GlobalKeys keys) {
    return [
      FocusTarget(
        id: "wallet_card",
        align: ContentAlign.bottom,
        child: keys['walletCard']!,
        text: "Votre Solde",
        description:
            "Consultez vos gains en temps réel et demandez des retraits vers Mobile Money.",
        borderRadius: BorderRadius.circular(20),
      ),
      FocusTarget(
        id: "stats_section",
        align: ContentAlign.top,
        child: keys['statsSection']!,
        text: "Vos Performances",
        description:
            "Suivez votre note moyenne, le nombre de missions réussies et votre taux d'acceptation.",
        borderRadius: BorderRadius.circular(20),
      ),
      FocusTarget(
        id: "timeline_missions",
        align: ContentAlign.top,
        child: keys['timelineMissions']!,
        text: "Timeline des Missions",
        description:
            "Visualisez toutes vos missions : à venir, en cours et terminées.",
        borderRadius: BorderRadius.circular(20),
      ),
      FocusTarget(
        id: "boost_button",
        align: ContentAlign.left,
        child: keys['boostButton']!,
        text: "Boost de Visibilité",
        description:
            "Augmentez votre visibilité auprès des clients en activant un Boost premium.",
        borderRadius: BorderRadius.circular(20),
      ),
      FocusTarget(
        id: "online_toggle",
        align: ContentAlign.right,
        child: keys['onlineToggle']!,
        text: "Statut En Ligne",
        description:
            "Activez/désactivez votre disponibilité pour recevoir de nouvelles missions.",
        borderRadius: BorderRadius.circular(20),
      ),
    ];
  }

  /// Génère les cibles pour l'écran de création de mission (Client)
  List<FocusTarget> getClientCreateMissionTargets(GlobalKeys keys) {
    return [
      FocusTarget(
        id: "mission_type",
        align: ContentAlign.bottom,
        child: keys['missionType']!,
        text: "Type de Mission",
        description: "Sélectionnez la catégorie de service dont vous avez besoin.",
        borderRadius: BorderRadius.circular(16),
      ),
      FocusTarget(
        id: "mission_details",
        align: ContentAlign.top,
        child: keys['missionDetails']!,
        text: "Détails",
        description:
            "Décrivez précisément votre besoin pour que les agents puissent vous aider efficacement.",
        borderRadius: BorderRadius.circular(16),
      ),
      FocusTarget(
        id: "location_picker",
        align: ContentAlign.bottom,
        child: keys['locationPicker']!,
        text: "Localisation",
        description: "Indiquez où la mission doit se dérouler avec précision.",
        borderRadius: BorderRadius.circular(16),
      ),
      FocusTarget(
        id: "budget_input",
        align: ContentAlign.top,
        child: keys['budgetInput']!,
        text: "Budget",
        description:
            "Définissez votre budget ou laissez les agents faire des offres.",
        borderRadius: BorderRadius.circular(16),
      ),
    ];
  }

  /// Génère les cibles pour l'écran des missions actives (Agent)
  List<FocusTarget> getActiveMissionTargets(GlobalKeys keys) {
    return [
      FocusTarget(
        id: "proof_upload",
        align: ContentAlign.bottom,
        child: keys['proofUpload']!,
        text: "Preuves Photo",
        description:
            "Prenez des photos pour valider chaque étape de la mission (arrivée, début, fin).",
        borderRadius: BorderRadius.circular(16),
      ),
      FocusTarget(
        id: "chat_button",
        align: ContentAlign.left,
        child: keys['chatButton']!,
        text: "Chat Client",
        description: "Communiquez directement avec votre client pendant la mission.",
        borderRadius: BorderRadius.circular(16),
      ),
      FocusTarget(
        id: "complete_button",
        align: ContentAlign.top,
        child: keys['completeButton']!,
        text: "Terminer la Mission",
        description:
            "Soumettez la mission terminée avec vos preuves pour recevoir le paiement.",
        borderRadius: BorderRadius.circular(16),
      ),
    ];
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
    keys.forEach((key, value) {
      if (value == null) {
        this[key] = GlobalKey();
      }
    });
  }
}
