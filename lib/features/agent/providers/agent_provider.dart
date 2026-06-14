import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import 'package:fonaco/core/providers/auth_provider.dart';
import 'package:fonaco/core/config/app_configuration.dart';
import 'package:fonaco/core/models/mission_model.dart';
import 'package:fonaco/core/services/location_service.dart';
import 'package:fonaco/core/services/cache_service.dart';
import 'package:fonaco/features/agent/data/repositories/agent_mission_repository_impl.dart';
import 'package:fonaco/features/agent/data/repositories/agent_profile_repository_impl.dart';
import 'package:fonaco/features/agent/data/repositories/agent_wallet_repository_impl.dart';
import 'package:fonaco/features/agent/domain/repositories/agent_mission_repository.dart';
import 'package:fonaco/features/agent/domain/repositories/agent_profile_repository.dart';
import 'package:fonaco/features/agent/domain/repositories/agent_wallet_repository.dart';

/// Provider pour gérer l'état de l'interface Agent
class AgentProvider extends ChangeNotifier {
  final Logger _logger = Logger();
  final AgentMissionRepository _missionRepository;
  final AgentWalletRepository _walletRepository;
  final AgentProfileRepository _profileRepository;
  final CacheService _cacheService;

  AgentProvider({
    AgentMissionRepository? missionRepository,
    AgentWalletRepository? walletRepository,
    AgentProfileRepository? profileRepository,
    CacheService? cacheService,
  })  : _missionRepository =
            missionRepository ?? AgentMissionRepositoryImpl(),
        _walletRepository = walletRepository ?? AgentWalletRepositoryImpl(),
        _profileRepository = profileRepository ?? AgentProfileRepositoryImpl(),
        _cacheService = cacheService ?? CacheService();

  bool _isLoading = false;
  String? _errorMessage;

  double _balance = 0.0;
  List<Map<String, dynamic>> _transactions = [];
  List<MissionModel> _availableMissions = [];
  List<MissionModel> _assignedMissions = [];
  List<MissionModel> _activeMissions = [];
  bool _isOnline = false;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _boostPlans = [];
  Map<String, dynamic>? _activeBoost;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get balance => _balance;
  List<Map<String, dynamic>> get transactions => _transactions;
  List<MissionModel> get availableMissions => _availableMissions;
  List<MissionModel> get assignedMissions => _assignedMissions;
  List<MissionModel> get activeMissions => _activeMissions;
  bool get isOnline => _isOnline;
  Map<String, dynamic> get stats => _stats;
  List<Map<String, dynamic>> get boostPlans => _boostPlans;
  Map<String, dynamic>? get activeBoost => _activeBoost;

  AgentMissionRepository get missionRepository => _missionRepository;
  AgentWalletRepository get walletRepository => _walletRepository;
  AgentProfileRepository get profileRepository => _profileRepository;

  Future<void> initAgentData() async {
    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      if (!_cacheService.isInitialized) {
        await _cacheService.init().catchError((e) {
          _logger.w('CacheService init failed: $e');
        });
      }

      final locationService = LocationService();
      var position = locationService.currentPosition;
      if (position == null) {
        await locationService.checkAndRequestLocation();
        await locationService.getCurrentLocation();
        position = locationService.currentPosition;
      }

      final results = await Future.wait(
        [
          _walletRepository.getBalance(),
          _missionRepository.getStatistics(),
          _missionRepository.getAvailable(
            latitude: position?.latitude,
            longitude: position?.longitude,
          ),
        ],
        eagerError: false,
      );

      var hasData = false;
      if (results[0] is double) {
        _balance = results[0] as double;
        hasData = true;
      }
      if (results[1] is Map<String, dynamic>) {
        _stats = results[1] as Map<String, dynamic>;
        hasData = true;
      }
      if (results[2] is List<MissionModel>) {
        _availableMissions = results[2] as List<MissionModel>;
        hasData = true;
      }

      if (hasData) notifyListeners();
    } catch (e, st) {
      _logger.e('initAgentData', error: e, stackTrace: st);
      _setError('Erreur lors du chargement des données: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchWalletDetails() async {
    _setLoading(true);
    _clearError();

    try {
      final results = await Future.wait([
        _walletRepository.getBalance(),
        _walletRepository.getTransactions(),
      ], eagerError: false);

      if (results[0] is double) _balance = results[0] as double;
      if (results[1] is List<Map<String, dynamic>>) {
        _transactions = results[1] as List<Map<String, dynamic>>;
      }
      notifyListeners();
    } catch (e, st) {
      _logger.e('fetchWalletDetails', error: e, stackTrace: st);
      _setError('Erreur lors du chargement du portefeuille: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshDashboardData() async {
    _clearError();

    try {
      final locationService = LocationService();
      var position = locationService.currentPosition;
      if (position == null) {
        await locationService.checkAndRequestLocation();
        await locationService.getCurrentLocation();
        position = locationService.currentPosition;
      }

      final results = await Future.wait([
        _walletRepository.getBalance(),
        _missionRepository.getAvailable(
          latitude: position?.latitude,
          longitude: position?.longitude,
        ),
      ]);

      if (results[0] is double) _balance = results[0] as double;
      if (results[1] is List<MissionModel>) {
        _availableMissions = results[1] as List<MissionModel>;
      }
      notifyListeners();
    } catch (e, st) {
      _logger.e('refreshDashboardData', error: e, stackTrace: st);
      _setError('Erreur lors du rafraîchissement: ${e.toString()}');
    }
  }

  Future<void> fetchAvailableMissions({
    bool filterByZone = false,
  }) async {
    try {
      final position = LocationService().currentPosition;
      _availableMissions = await _missionRepository.getAvailable(
        latitude: position?.latitude,
        longitude: position?.longitude,
        filterByZone: filterByZone,
      );
      notifyListeners();
    } catch (e, st) {
      _logger.e('fetchAvailableMissions', error: e, stackTrace: st);
      _setError('Erreur lors du chargement des missions: ${e.toString()}');
    }
  }

  List<MissionModel> _mergeActiveMissions(
    List<MissionModel> local,
    List<MissionModel> remote,
  ) {
    final merged = <String, MissionModel>{
      for (final m in remote) m.id: m,
    };
    for (final m in local) {
      if (!merged.containsKey(m.id) &&
          MissionModel.isActiveLifecycle(m.status)) {
        merged[m.id] = m;
      }
    }
    final list = merged.values.toList();
    list.sort((a, b) {
      final aDate = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return list;
  }

  Future<void> fetchActiveMissions() async {
    try {
      final remote = await _missionRepository.getActive();
      _activeMissions = _mergeActiveMissions(_activeMissions, remote);
      notifyListeners();
    } catch (e, st) {
      _logger.e('fetchActiveMissions', error: e, stackTrace: st);
    }
  }

  Future<void> fetchAssignedMissions() async {
    try {
      _assignedMissions = await _missionRepository.getAssigned();
      notifyListeners();
    } catch (e, st) {
      _logger.e('fetchAssignedMissions', error: e, stackTrace: st);
    }
  }

  Future<bool> declineAssignedMission(String missionId) async {
    try {
      final success = await _missionRepository.declineAssignment(missionId);
      if (success) {
        _assignedMissions =
            _assignedMissions.where((m) => m.id != missionId).toList();
        notifyListeners();
      }
      return success;
    } catch (e, st) {
      _logger.e('declineAssignedMission', error: e, stackTrace: st);
      return false;
    }
  }

  Future<void> fetchBoostData() async {
    try {
      final results = await Future.wait([
        _profileRepository.getBoostPlans(),
        _profileRepository.getActiveBoost(),
      ]);
      if (results[0] is List<Map<String, dynamic>>) {
        final plans = results[0] as List<Map<String, dynamic>>;
        _boostPlans = plans.isNotEmpty
            ? plans
            : List<Map<String, dynamic>>.from(
                AppConfiguration.instance.defaultBoostPlans,
              );
      } else {
        _boostPlans = List<Map<String, dynamic>>.from(
          AppConfiguration.instance.defaultBoostPlans,
        );
      }
      _activeBoost = results[1] as Map<String, dynamic>?;
      notifyListeners();
    } catch (e, st) {
      _logger.e('fetchBoostData', error: e, stackTrace: st);
      _boostPlans = List<Map<String, dynamic>>.from(
        AppConfiguration.instance.defaultBoostPlans,
      );
      notifyListeners();
    }
  }

  Future<void> syncOnlineStatus() async {
    try {
      final profile = await _profileRepository.getProfile();
      final online = profile['is_online'] == true;
      _isOnline = online;
      notifyListeners();
    } catch (e, st) {
      _logger.e('syncOnlineStatus', error: e, stackTrace: st);
    }
  }

  Future<void> fetchStats() async {
    try {
      _stats = await _missionRepository.getStatistics();
      notifyListeners();
    } catch (e, st) {
      _logger.e('fetchStats', error: e, stackTrace: st);
      _setError('Erreur lors du chargement des statistiques: ${e.toString()}');
    }
  }

  Future<WithdrawResult> requestWithdrawal({
    required double amount,
    required String paymentMethod,
    required String phoneNumber,
  }) async {
    try {
      final result = await _walletRepository.withdraw(
        amount: amount,
        paymentMethod: paymentMethod,
        phoneNumber: phoneNumber,
      );
      if (result.success) {
        await fetchWalletDetails();
      }
      return result;
    } catch (e, st) {
      _logger.e('requestWithdrawal', error: e, stackTrace: st);
      _setError('Erreur lors de la demande de retrait: ${e.toString()}');
      return WithdrawResult(
        success: false,
        message: 'Erreur lors de la demande de retrait: ${e.toString()}',
      );
    }
  }

  Future<MissionAcceptResult> acceptMissionAndUpdateState(
    String missionId,
  ) async {
    try {
      final result = await _missionRepository.accept(missionId);
      if (result.success) {
        _clearError();
        final accepted = result.mission ??
            _availableMissions
                .firstWhere(
                  (m) => m.id == missionId,
                  orElse: () => MissionModel(
                    id: missionId,
                    title: '',
                    description: '',
                    price: 0,
                    status: MissionStatus.ACCEPTED,
                  ),
                )
                .copyWith(status: MissionStatus.ACCEPTED);
        _availableMissions =
            _availableMissions.where((m) => m.id != missionId).toList();
        _assignedMissions =
            _assignedMissions.where((m) => m.id != missionId).toList();
        if (!_activeMissions.any((m) => m.id == missionId)) {
          _activeMissions = [accepted, ..._activeMissions];
        }
        notifyListeners();
        await Future.wait([
          fetchAvailableMissions(),
          fetchAssignedMissions(),
          fetchActiveMissions(),
          fetchStats(),
        ]);
      } else if (result.message != null) {
        _setError(result.message!);
      }
      return result;
    } catch (e, st) {
      _logger.e('acceptMissionAndUpdateState', error: e, stackTrace: st);
      _setError('Erreur lors de l\'acceptation: ${e.toString()}');
      return MissionAcceptResult(
        success: false,
        message: 'Erreur lors de l\'acceptation: ${e.toString()}',
      );
    }
  }

  bool canAccessAgentMode(AuthProvider authProvider) {
    if (!authProvider.isAuthenticated) return false;
    final currentUser = authProvider.currentUser;
    if (currentUser == null) return false;
    return currentUser.isAgent;
  }

  void updateBalance(double newBalance) {
    _balance = newBalance;
    notifyListeners();
  }

  void updateAvailableMissions(List<MissionModel> missions) {
    _availableMissions = missions;
    notifyListeners();
  }

  Future<void> toggleOnlineStatus() async {
    try {
      final newStatus = !_isOnline;
      final success =
          await _profileRepository.updateStatus(isOnline: newStatus);
      if (success) {
        _isOnline = newStatus;
        notifyListeners();
      } else {
        _setError('Impossible de modifier le statut en ligne');
      }
    } catch (e, st) {
      _logger.e('toggleOnlineStatus', error: e, stackTrace: st);
      _setError('Erreur lors du changement de statut: ${e.toString()}');
    }
  }

  void setOnlineStatus(bool isOnline) {
    _isOnline = isOnline;
    notifyListeners();
  }

  Future<bool> submitReview(
    String missionId,
    int rating,
    String comment,
  ) async {
    try {
      final success =
          await _missionRepository.submitReview(missionId, rating, comment);
      if (success) {
        _stats = await _missionRepository.getStatistics();
      } else {
        _setError('Impossible de soumettre l\'avis');
      }
      return success;
    } catch (e, st) {
      _logger.e('submitReview', error: e, stackTrace: st);
      _setError('Erreur lors de la soumission de l\'avis: ${e.toString()}');
      return false;
    }
  }

  Future<bool> depositWallet({
    required double amount,
    required String paymentMethod,
    String? paymentReference,
  }) async {
    try {
      final success = await _walletRepository.deposit(
        amount: amount,
        paymentMethod: paymentMethod,
        paymentReference: paymentReference,
      );
      if (success) {
        await fetchWalletDetails();
      }
      return success;
    } catch (e, st) {
      _logger.e('depositWallet', error: e, stackTrace: st);
      return false;
    }
  }

  void reset() {
    _isLoading = false;
    _errorMessage = null;
    _balance = 0.0;
    _transactions = [];
    _availableMissions = [];
    _activeMissions = [];
    _isOnline = false;
    _stats = {};
    _boostPlans = [];
    _activeBoost = null;
    notifyListeners();
  }

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
