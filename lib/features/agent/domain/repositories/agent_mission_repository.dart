import 'package:fonaco/core/models/mission_model.dart';

/// Résultat d'une tentative d'acceptation de mission.
class MissionAcceptResult {
  final bool success;
  final bool conflict;
  final String? message;
  final MissionModel? mission;

  const MissionAcceptResult({
    required this.success,
    this.conflict = false,
    this.message,
    this.mission,
  });
}

/// Contrat missions côté agent (disponibles, suivi, statistiques).
abstract class AgentMissionRepository {
  Future<List<MissionModel>> getAvailable({
    double? latitude,
    double? longitude,
    int? radius,
    bool filterByZone = false,
  });

  Future<List<MissionModel>> getAssigned({int limit = 50});

  Future<List<MissionModel>> getHistory({int limit = 20});

  Future<List<MissionModel>> getActive({int limit = 50});

  Future<MissionAcceptResult> accept(String missionId);

  Future<bool> declineAssignment(String missionId);

  Future<bool> startMission(String missionId);

  Future<bool> updateSteps(
    String missionId,
    String status, {
    double? latitude,
    double? longitude,
  });

  Future<bool> submitCompletion(String missionId, String photoPath);

  Future<bool> rateClient({
    required String missionId,
    required String clientId,
    required int rating,
    String? comment,
  });

  Future<Map<String, dynamic>> getStatistics();

  Future<String?> downloadMonthlyReport({int? month, int? year});

  Future<List<MissionModel>> getDisputed({int limit = 50});

  /// Complément cycle mission active (hors contrat minimal Sprint 0).
  Future<bool> validateCompletion(String missionId, String qrCodeData);

  Future<bool> submitReview(String missionId, int rating, String comment);

  Future<bool> openDispute(
    String missionId,
    String reason,
    String description,
  );

  Future<bool> createDispute({
    required String missionId,
    required String title,
    required String description,
    String priority = 'medium',
  });
}
