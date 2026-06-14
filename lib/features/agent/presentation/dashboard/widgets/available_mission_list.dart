import 'package:flutter/material.dart';

import 'package:fonaco/core/models/mission_model.dart';
import 'package:fonaco/features/agent/presentation/dashboard/widgets/mission_card.dart';
import 'package:fonaco/features/agent/widgets/shimmer_loading_card.dart';

/// Liste des missions disponibles pour le dashboard agent.
class AvailableMissionList extends StatelessWidget {
  final List<MissionModel> missions;
  final bool isLoading;
  final VoidCallback onRefreshAfterConflict;

  const AvailableMissionList({
    super.key,
    required this.missions,
    required this.isLoading,
    required this.onRefreshAfterConflict,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Column(
        children: List.generate(
          3,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: ShimmerLoadingCard(
              width: double.infinity,
              height: 140,
              borderRadius: BorderRadius.all(Radius.circular(22)),
            ),
          ),
        ),
      );
    }

    if (missions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aucune mission disponible pour le moment. '
              'Restez en ligne pour recevoir les prochaines opportunités !',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: missions
          .map(
            (mission) => MissionCard(
              key: ValueKey(mission.id),
              mission: mission,
              onConflict: onRefreshAfterConflict,
            ),
          )
          .toList(),
    );
  }
}
