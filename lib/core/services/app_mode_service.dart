import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../providers/auth_provider.dart';

/// Énumération pour les différents modes de l'application
enum AppMode {
  CLIENT,
  AGENT,
}

/// Service pour gérer la bascule globale entre AppMode.CLIENT et AppMode.AGENT
class AppModeService extends ChangeNotifier {
  final Logger _logger = Logger();
  static final AppModeService _instance = AppModeService._internal();
  factory AppModeService() => _instance;
  AppModeService._internal();

  AppMode _currentMode = AppMode.CLIENT;
  bool _isTransitioning = false;
  String? _lastError;

  // Getters
  AppMode get currentMode => _currentMode;
  bool get isAgentMode => _currentMode == AppMode.AGENT;
  bool get isClientMode => _currentMode == AppMode.CLIENT;
  bool get isTransitioning => _isTransitioning;
  String? get lastError => _lastError;

  /// Bascule vers le mode Agent avec vérifications complètes
  /// Retourne true si le basculement a réussi, false sinon
  Future<bool> switchToAgent(AuthProvider authProvider) async {
    if (_isTransitioning) {
      _logger.w('Transition déjà en cours');
      return false;
    }

    _setTransitioning(true);
    _clearError();

    try {
      // 1. Vérifier si l'utilisateur est authentifié
      if (!authProvider.isAuthenticated) {
        _setError('Vous devez être connecté pour accéder au mode Agent');
        return false;
      }

      final currentUser = authProvider.currentUser;
      if (currentUser == null) {
        _setError('Utilisateur non trouvé');
        return false;
      }

      // 2. Vérifier si l'utilisateur a le droit d'être Agent
      if (!currentUser.isAgent) {
        if (currentUser.isClient) {
          _setError('Votre compte est de type Client. Pour devenir Agent, veuillez contacter le support.');
        } else {
          _setError('Votre compte n\'est pas configuré pour être Agent');
        }
        return false;
      }

      // 3. Vérifier si le numéro de téléphone est valide
      if (currentUser.phoneNumber == null || currentUser.phoneNumber!.isEmpty) {
        _setError('Un numéro de téléphone valide est requis pour accéder au mode Agent');
        return false;
      }

      // 4. Vérifier si la localisation est disponible (via LocationService)
      final locationCheck = await _checkLocationAvailability();
      if (!locationCheck) {
        _setError('La localisation est requise pour accéder au mode Agent. Veuillez l\'activer dans les paramètres.');
        return false;
      }

      // 5. Effectuer la bascule
      _currentMode = AppMode.AGENT;
      _logger.i('Basculement vers mode Agent réussi pour utilisateur ${currentUser.id}');
      notifyListeners();
      return true;

    } catch (e, st) {
      _logger.e('Erreur lors du basculement vers mode Agent', error: e, stackTrace: st);
      _setError('Une erreur est survenue: ${e.toString()}');
      return false;
    } finally {
      _setTransitioning(false);
    }
  }

  /// Bascule vers le mode Client
  /// Retourne true si le basculement a réussi, false sinon
  Future<bool> switchToClient() async {
    if (_isTransitioning) {
      _logger.w('Transition déjà en cours');
      return false;
    }

    _setTransitioning(true);
    _clearError();

    try {
      _currentMode = AppMode.CLIENT;
      _logger.i('Basculement vers mode Client réussi');
      notifyListeners();
      return true;
    } catch (e, st) {
      _logger.e('Erreur lors du basculement vers mode Client', error: e, stackTrace: st);
      _setError('Une erreur est survenue: ${e.toString()}');
      return false;
    } finally {
      _setTransitioning(false);
    }
  }

  /// Bascule entre les modes (toggle)
  Future<bool> toggleMode(AuthProvider authProvider) async {
    if (_currentMode == AppMode.CLIENT) {
      return await switchToAgent(authProvider);
    } else {
      return await switchToClient();
    }
  }

  /// Force le changement de mode (pour les tests ou admin)
  void forceMode(AppMode mode) {
    _currentMode = mode;
    _logger.d('Mode forcé: $mode');
    notifyListeners();
  }

  /// Réinitialise le service
  void reset() {
    _currentMode = AppMode.CLIENT;
    _isTransitioning = false;
    _lastError = null;
    notifyListeners();
  }

  /// Vérifie la disponibilité de la localisation
  Future<bool> _checkLocationAvailability() async {
    try {
      // Import dynamique pour éviter les dépendances circulaires
      final locationService = await _importLocationService();
      if (locationService == null) {
        _logger.w('LocationService non disponible');
        return false;
      }

      final permissionStatus = await locationService.checkAndRequestLocation();
      return permissionStatus.name == 'granted';
    } catch (e) {
      _logger.e('Erreur lors de la vérification de la localisation: $e');
      return false;
    }
  }

  /// Import dynamique du LocationService pour éviter les dépendances circulaires
  Future<dynamic> _importLocationService() async {
    try {
      // Cette méthode sera implémentée quand nous aurons accès au LocationService
      // Pour l'instant, nous retournons true pour les tests
      return null;
    } catch (e) {
      _logger.e('Erreur import LocationService: $e');
      return null;
    }
  }

  // Méthodes privées pour la gestion d'état
  void _setTransitioning(bool transitioning) {
    _isTransitioning = transitioning;
    notifyListeners();
  }

  void _setError(String error) {
    _lastError = error;
    notifyListeners();
  }

  void _clearError() {
    _lastError = null;
    notifyListeners();
  }
}
