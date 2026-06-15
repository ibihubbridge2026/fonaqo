import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../core/config/api_config.dart';
import '../data/repositories/agent_mission_repository_impl.dart';
import '../domain/repositories/agent_mission_repository.dart';

/// Service pour gérer la timeline dynamique des missions
class MissionTimelineService {
  final AgentMissionRepository _repository = AgentMissionRepositoryImpl();
  final Logger _logger = Logger();
  WebSocketChannel? _timelineWebSocket;

  /// Connecte au WebSocket timeline d'une mission
  void connectToTimeline(
      String missionId, Function(Map<String, dynamic>) onStepUpdate) {
    try {
      final wsUrl = ApiConfig.wsUrl('/ws/timeline/$missionId/');
      _timelineWebSocket = WebSocketChannel.connect(Uri.parse(wsUrl));

      _timelineWebSocket!.stream.listen(
        (data) {
          final stepData = json.decode(data) as Map<String, dynamic>;
          onStepUpdate(stepData);
        },
        onError: (error) {
          _logger.e('Erreur WebSocket Timeline: $error');
        },
        onDone: () {
          _logger.w('WebSocket Timeline déconnecté');
        },
      );

      _logger.d('Timeline connectée pour mission $missionId');
    } catch (e) {
      _logger.e('Erreur connexion Timeline: $e');
    }
  }

  /// Met à jour une étape de mission via API
  Future<bool> updateMissionStep(
      String missionId, String stepName, Map<String, dynamic>? metadata) async {
    try {
      final success = await _repository.updateSteps(missionId, stepName);

      if (success) {
        // Notifier via WebSocket si disponible
        _notifyStepUpdate(missionId, stepName, metadata);
      }

      return success;
    } catch (e) {
      _logger.e('Erreur updateMissionStep: $e');
      return false;
    }
  }

  /// Notifie la mise à jour d'étape via WebSocket
  void _notifyStepUpdate(
      String missionId, String stepName, Map<String, dynamic>? metadata) {
    if (_timelineWebSocket == null) return;

    final notification = {
      'type': 'step_update',
      'mission_id': missionId,
      'step_name': stepName,
      'timestamp': DateTime.now().toIso8601String(),
      'metadata': metadata ?? {},
    };

    try {
      _timelineWebSocket!.sink.add(json.encode(notification));
    } catch (e) {
      _logger.e('Erreur notification step update: $e');
    }
  }

  /// Arrête la connexion timeline
  void disconnect() {
    _timelineWebSocket?.sink.close();
    _timelineWebSocket = null;
  }
}
