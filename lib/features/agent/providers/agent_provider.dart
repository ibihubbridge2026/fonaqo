import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/mission_model.dart';
import '../repository/agent_repository.dart';
import '../../../core/services/location_service.dart';

/// Provider pour gérer l'état de l'interface Agent
class AgentProvider extends ChangeNotifier {
  final Logger _logger = Logger();
  final AgentRepository _agentRepository = AgentRepository();

  bool _isLoading = false;
  String? _errorMessage;

  // Variables d'état initiales pour l'Agent
  double _balance = 0.0;
  List<Map<String, dynamic>> _transactions = [];
  List<MissionModel> _availableMissions = [];
  bool _isOnline = false;
  Map<String, dynamic> _stats = {};

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get balance => _balance;
  List<Map<String, dynamic>> get transactions => _transactions;
  List<MissionModel> get availableMissions => _availableMissions;
  bool get isOnline => _isOnline;
  Map<String, dynamic> get stats => _stats;

  /// Initialise les données de l'agent depuis le backend avec localisation GPS
  Future<void> initAgentData() async {
    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      // Récupérer la position GPS actuelle
      final locationService = LocationService();
      final position = locationService.currentPosition;

      // Si pas de position, essayer de la récupérer
      if (position == null) {
        await locationService.checkAndRequestLocation();
        await locationService.getCurrentLocation();
      }

      // Appels parallèles pour optimiser le temps de chargement
      final results = await Future.wait(
        [
          _agentRepository.getAgentBalance(),
          _agentRepository.getAgentStats(),
          _agentRepository.getAvailableMissions(
            latitude: position?.latitude,
            longitude: position?.longitude,
          ),
        ],
        eagerError: false, // Continue même si une requête échoue
      );

      // Mise à jour progressive des données
      bool hasData = false;

      if (results[0] != null && results[0] is double) {
        _balance = results[0] as double;
        hasData = true;
      }

      if (results[1] != null && results[1] is Map<String, dynamic>) {
        _stats = results[1] as Map<String, dynamic>;
        hasData = true;
      }

      if (results[2] != null && results[2] is List<MissionModel>) {
        _availableMissions =
            (results[2] as List<MissionModel>).take(3).toList();
        hasData = true;
      }

      if (hasData) {
        _logger.d(
            'Données agent initialisées: solde=$_balance, missions=${_availableMissions.length} avec GPS');
        notifyListeners();
      }
    } catch (e, st) {
      _logger.e('Erreur initialisation données agent',
          error: e, stackTrace: st);
      _setError('Erreur lors du chargement des données: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // =========================
  // WALLET DETAILS
  // =========================

  /// Récupère les détails complets du portefeuille (solde + transactions)
  Future<void> fetchWalletDetails() async {
    _setLoading(true);
    _clearError();

    try {
      final results = await Future.wait([
        _agentRepository.getWalletBalance(),
        _agentRepository.getWalletTransactions(),
      ], eagerError: false);

      // Mettre à jour le solde
      if (results[0] is double) {
        _balance = results[0] as double;
      }

      // Mettre à jour les transactions
      if (results[1] is List) {
        _transactions = results[1] as List<Map<String, dynamic>>;
      }

      _logger.d(
          'Détails portefeuille récupérés: solde=$_balance, transactions=${_transactions.length}');
      notifyListeners();
    } catch (e, st) {
      _logger.e('Erreur récupération détails portefeuille',
          error: e, stackTrace: st);
      _setError('Erreur lors du chargement du portefeuille: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Rafraîchit uniquement les données de solde et missions avec GPS (pour pull-to-refresh)
  Future<void> refreshDashboardData() async {
    _clearError();

    try {
      final locationService = LocationService();
      final position = locationService.currentPosition;

      // Si pas de position, essayer de la récupérer
      if (position == null) {
        await locationService.checkAndRequestLocation();
        await locationService.getCurrentLocation();
      }

      final results = await Future.wait([
        _agentRepository.getAgentBalance(),
        _agentRepository.getAvailableMissions(
          latitude: position?.latitude,
          longitude: position?.longitude,
        ),
      ]);

      if (results[0] is double) {
        _balance = results[0] as double;
      }

      if (results[1] is List<MissionModel>) {
        _availableMissions =
            (results[1] as List<MissionModel>).take(3).toList();
      }

      _logger.d('Données dashboard rafraîchies avec GPS');
      notifyListeners();
    } catch (e, st) {
      _logger.e('Erreur rafraîchissement dashboard', error: e, stackTrace: st);
      _setError('Erreur lors du rafraîchissement: ${e.toString()}');
    }
  }

  /// Demande un retrait de fonds
  Future<bool> requestWithdrawal(double amount, String provider) async {
    try {
      final response =
          await _agentRepository.requestWithdrawal(amount, provider);

      if (response) {
        _logger.d('Demande de retrait envoyée: $amount $provider');
        return true;
      } else {
        _logger.e('Erreur demande retrait');
        return false;
      }
    } catch (e, st) {
      _logger.e('Erreur requestWithdrawal', error: e, stackTrace: st);
      _setError('Erreur lors de la demande de retrait: ${e.toString()}');
      return false;
    }
  }

  /// Accepte une mission et met à jour l'état du provider
  Future<void> acceptMissionAndUpdateState(String missionId) async {
    try {
      final success = await _agentRepository.acceptMission(missionId);

      if (success) {
        // Mettre à jour l'état du provider
        _setLoading(true);
        _clearError();

        // Rafraîchir les données après acceptation
        await refreshDashboardData();

        _logger.d('Mission acceptée et état mis à jour: $missionId');
      }
    } catch (e, st) {
      _logger.e('Erreur acceptation mission avec mise à jour état',
          error: e, stackTrace: st);
      _setError('Erreur lors de l\'acceptation: ${e.toString()}');
    }
  }

  /// Bascule vers le mode agent si l'utilisateur a les droits nécessaires
  /// Retourne true si le basculement a réussi, false sinon

  /// Vérifie si l'utilisateur peut accéder au mode agent

  /// Force l'activation du mode agent (pour les tests ou admin)

  /// Met à jour le solde de l'agent
  void updateBalance(double newBalance) {
    _balance = newBalance;
    _logger.d('Solde agent mis à jour: $_balance');
    notifyListeners();
  }

  /// Met à jour la liste des missions disponibles
  void updateAvailableMissions(List<MissionModel> missions) {
    _availableMissions = missions;
    _logger
        .d('Missions disponibles mises à jour: ${_availableMissions.length}');
    notifyListeners();
  }

  /// Bascule le statut en ligne de l'agent (synchronisé avec l'API)
  Future<void> toggleOnlineStatus() async {
    try {
      final newStatus = !_isOnline;
      final success = await _agentRepository.updateOnlineStatus(newStatus);

      if (success) {
        _isOnline = newStatus;
        _logger.d('Statut online agent basculé: $_isOnline');
        notifyListeners();
      } else {
        _setError('Impossible de modifier le statut en ligne');
      }
    } catch (e, st) {
      _logger.e('Erreur toggleOnlineStatus', error: e, stackTrace: st);
      _setError('Erreur lors du changement de statut: ${e.toString()}');
    }
  }

  /// Définit le statut en ligne de l'agent (sans synchronisation API)
  void setOnlineStatus(bool isOnline) {
    _isOnline = isOnline;
    _logger.d('Statut online agent défini: $_isOnline');
    notifyListeners();
  }

  /// Soumet une évaluation pour une mission
  Future<bool> submitReview(
      String missionId, int rating, String comment) async {
    try {
      final success =
          await _agentRepository.submitReview(missionId, rating, comment);

      if (success) {
        _logger.d('Avis soumis avec succès pour mission $missionId');
        // Rafraîchir les statistiques de l'agent
        final statsData = await _agentRepository.getAgentStats();
        _stats = statsData;
      } else {
        _setError('Impossible de soumettre l\'avis');
      }

      return success;
    } catch (e, st) {
      _logger.e('Erreur submitReview', error: e, stackTrace: st);
      _setError('Erreur lors de la soumission de l\'avis: ${e.toString()}');
      return false;
    }
  }

  /// Réinitialise le provider
  void reset() {
    _isLoading = false;
    _errorMessage = null;
    _balance = 0.0;
    _availableMissions = [];
    _isOnline = false;
    _stats = {};
    notifyListeners();
  }

  // Méthodes privées pour la gestion d'état
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
