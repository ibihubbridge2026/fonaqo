import 'package:flutter/foundation.dart';

import 'package:fonaco/core/models/mission_model.dart';
import 'package:fonaco/core/providers/mission_provider.dart';
import 'package:fonaco/core/services/dashboard_refresh_service.dart';
import 'package:fonaco/features/agent/providers/agent_provider.dart';

/// Propagation d'état mission après événements push / litige / validation.
class MissionStateSyncService {
  MissionStateSyncService._();
  static final MissionStateSyncService instance = MissionStateSyncService._();

  static const _missionSyncTypes = {
    'DISPUTE_RESOLVED',
    'DISPUTE_ARBITRAGED',
    'MISSION_PROOF_SUBMITTED',
    'MISSION_STATUS_CHANGED',
    'MISSION_VALIDATED',
    'MISSION_COMPLETED',
  };

  /// Rafraîchit les listes client + agent quand une notification porte un mission_id.
  Future<void> handleNotificationData(
    Map<String, dynamic> data, {
    MissionProvider? missionProvider,
    AgentProvider? agentProvider,
  }) async {
    final type = data['type']?.toString() ?? '';
    final missionId = data['mission_id']?.toString() ?? '';
    if (missionId.isEmpty) return;
    if (!_missionSyncTypes.contains(type) &&
        !type.toUpperCase().contains('DISPUTE') &&
        !type.toUpperCase().contains('MISSION')) {
      return;
    }

    try {
      await missionProvider?.refreshMissionById(missionId);
      await missionProvider?.refreshMissions();
      await agentProvider?.refreshMissionFromServer(missionId);
      await agentProvider?.fetchActiveMissions();
      await agentProvider?.fetchStats();
      DashboardRefreshService.instance.requestRefresh();
    } catch (e, st) {
      debugPrint('MissionStateSyncService: $e\n$st');
    }
  }

  /// Applique un statut connu localement sans attendre l'API (fallback litige).
  void applyLocalStatus({
    required String missionId,
    required MissionStatus status,
    MissionProvider? missionProvider,
    AgentProvider? agentProvider,
  }) {
    final clientMissions = missionProvider?.missions ?? [];
    for (final m in clientMissions) {
      if (m.id == missionId) {
        missionProvider?.upsertMission(m.copyWith(status: status));
        break;
      }
    }
    agentProvider?.refreshMissionFromServer(missionId);
    DashboardRefreshService.instance.requestRefresh();
  }
}
