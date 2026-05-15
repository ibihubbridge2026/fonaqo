import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../core/config/api_config.dart';
import '../repository/agent_repository.dart';

/// Service pour gérer la timeline dynamique des missions
class MissionTimelineService {
  final AgentRepository _repository = AgentRepository();
  WebSocketChannel? _timelineWebSocket;
  
  /// Connecte au WebSocket timeline d'une mission
  void connectToTimeline(String missionId, Function(Map<String, dynamic>) onStepUpdate) {
    try {
      final wsUrl = 'ws://${ApiConfig.apiHostAndPort}/ws/timeline/$missionId/';
      _timelineWebSocket = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      _timelineWebSocket!.stream.listen(
        (data) {
          final stepData = json.decode(data) as Map<String, dynamic>;
          onStepUpdate(stepData);
        },
        onError: (error) {
          print('Erreur WebSocket Timeline: $error');
        },
        onDone: () {
          print('WebSocket Timeline déconnecté');
        },
      );
      
      print('Timeline connectée pour mission $missionId');
    } catch (e) {
      print('Erreur connexion Timeline: $e');
    }
  }
  
  /// Met à jour une étape de mission via API
  Future<bool> updateMissionStep(String missionId, String stepName, Map<String, dynamic>? metadata) async {
    try {
      final success = await _repository.updateMissionStep(missionId, stepName);
      
      if (success) {
        // Notifier via WebSocket si disponible
        _notifyStepUpdate(missionId, stepName, metadata);
      }
      
      return success;
    } catch (e) {
      print('Erreur updateMissionStep: $e');
      return false;
    }
  }
  
  /// Notifie la mise à jour d'étape via WebSocket
  void _notifyStepUpdate(String missionId, String stepName, Map<String, dynamic>? metadata) {
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
      print('Erreur notification step update: $e');
    }
  }
  
  /// Arrête la connexion timeline
  void disconnect() {
    _timelineWebSocket?.sink.close();
    _timelineWebSocket = null;
  }
}
