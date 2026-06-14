import 'package:flutter/material.dart';

import 'package:fonaco/core/models/mission_model.dart';

/// Timeline visuelle de la machine à états mission (agent).
class MissionStepTimeline extends StatelessWidget {
  final MissionStatus currentStatus;

  const MissionStepTimeline({
    super.key,
    required this.currentStatus,
  });

  static const _steps = [
    _StepDef('Mission acceptée', 'Prise en charge confirmée', Icons.check_circle),
    _StepDef('En route', 'Déplacement vers le client', Icons.directions_bike),
    _StepDef('Arrivé sur place', 'Au point de rendez-vous', Icons.place),
    _StepDef('En cours', 'Mission en réalisation', Icons.work_outline),
    _StepDef('Validation client', 'Preuve en attente de confirmation', Icons.fact_check),
    _StepDef('Terminée', 'Fonds libérés', Icons.verified),
  ];

  static const _statusOrder = [
    MissionStatus.ACCEPTED,
    MissionStatus.ON_THE_WAY,
    MissionStatus.ARRIVED,
    MissionStatus.IN_PROGRESS,
    MissionStatus.IN_PROGRESS_REVIEW,
    MissionStatus.COMPLETED,
  ];

  int _activeIndex(MissionStatus status) {
    if (status == MissionStatus.PENDING) return 0;
    if (status == MissionStatus.IN_PROGRESS_REVIEW) {
      return _statusOrder.indexOf(MissionStatus.IN_PROGRESS_REVIEW);
    }
    final idx = _statusOrder.indexOf(status);
    return idx >= 0 ? idx : 0;
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = _activeIndex(currentStatus);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: List.generate(_steps.length, (index) {
          final step = _steps[index];
          final isCompleted = index < activeIndex;
          final isCurrent = index == activeIndex;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: isCompleted || isCurrent
                          ? const Color(0xFF4CAF50)
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isCompleted ? Icons.check : step.icon,
                      color: isCompleted || isCurrent
                          ? Colors.white
                          : Colors.grey.shade500,
                      size: 20,
                    ),
                  ),
                  if (index != _steps.length - 1)
                    Container(
                      width: 2,
                      height: 45,
                      color: isCompleted
                          ? const Color(0xFF4CAF50)
                          : Colors.grey.shade300,
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isCompleted || isCurrent
                              ? Colors.black
                              : Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step.subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _StepDef {
  final String title;
  final String subtitle;
  final IconData icon;

  const _StepDef(this.title, this.subtitle, this.icon);
}
