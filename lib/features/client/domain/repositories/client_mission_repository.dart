import 'package:fonaco/core/models/mission_model.dart';
import 'package:fonaco/features/client/missions/mission_repository.dart';

/// Contrat repository missions côté client (aligné sur le pattern agent).
abstract class ClientMissionRepository {
  Future<List<MissionModel>> fetchMissionsList({
    double? latitude,
    double? longitude,
    int page = 1,
    int pageSize = 10,
  });

  Future<MissionModel> fetchMissionDetails(String missionId);

  Future<MissionModel> createMission(MissionCreatePayload payload);

  Future<MissionModel> cancelMission(String missionId);

  Future<MissionModel> releaseFunds(String missionId);
}
