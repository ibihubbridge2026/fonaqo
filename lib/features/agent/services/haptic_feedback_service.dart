import 'package:flutter/services.dart';

/// Service pour gérer les retours haptiques
class HapticFeedbackService {
  static final HapticFeedbackService _instance = HapticFeedbackService._internal();
  factory HapticFeedbackService() => _instance;
  HapticFeedbackService._internal();

  /// Retour léger pour les interactions courantes
  Future<void> lightImpact() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      // Ignorer les erreurs haptiques (certains appareils ne supportent pas)
    }
  }

  /// Retour moyen pour les actions importantes
  Future<void> mediumImpact() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      // Ignorer les erreurs haptiques
    }
  }

  /// Retour fort pour les succès majeurs
  Future<void> heavyImpact() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (e) {
      // Ignorer les erreurs haptiques
    }
  }

  /// Vibration de sélection (pour les changements de sélection)
  Future<void> selectionClick() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (e) {
      // Ignorer les erreurs haptiques
    }
  }

  /// Retour pour validation d'étape de mission
  Future<void> missionStepValidation() async {
    await lightImpact();
  }

  /// Retour pour succès financier (retrait/gains)
  Future<void> financialSuccess() async {
    await mediumImpact();
  }

  /// Retour pour mission acceptée
  Future<void> missionAccepted() async {
    await mediumImpact();
  }

  /// Retour pour mission terminée
  Future<void> missionCompleted() async {
    await heavyImpact();
  }

  /// Retour pour notification reçue
  Future<void> notificationReceived() async {
    await lightImpact();
  }

  /// Retour pour erreur
  Future<void> error() async {
    await mediumImpact();
  }

  /// Retour pour swipe action
  Future<void> swipeAction() async {
    await lightImpact();
  }

  /// Retour pour bouton pressé
  Future<void> buttonPress() async {
    await selectionClick();
  }
}
