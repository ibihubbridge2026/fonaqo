import 'package:flutter/material.dart';

import 'package:fonaco/core/models/mission_model.dart';
import 'package:fonaco/features/agent/screens/agent_active_mission_screen.dart';

/// Écran de suivi mission agent (wrapper sur le cycle mission active).
class AgentMissionTrackingScreen extends StatelessWidget {
  final MissionModel mission;

  const AgentMissionTrackingScreen({
    super.key,
    required this.mission,
  });

  @override
  Widget build(BuildContext context) {
    return AgentActiveMissionScreen(mission: mission);
  }
}
