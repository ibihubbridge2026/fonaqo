import 'package:flutter/material.dart';

import 'package:fonaco/core/models/mission_model.dart';
import 'package:fonaco/core/routes/app_routes.dart';
import 'package:fonaco/features/agent/presentation/dashboard/widgets/mission_card.dart';
import 'package:go_router/go_router.dart';

/// Carrousel horizontal de cartes mission (design dashboard agent).
class AgentMissionStrip extends StatelessWidget {
  final List<MissionModel> missions;
  final bool showAcceptButton;
  final double? cardHeight;
  final VoidCallback? onRefreshAfterConflict;
  final VoidCallback? onMissionAccepted;
  final String emptyMessage;

  const AgentMissionStrip({
    super.key,
    required this.missions,
    this.showAcceptButton = true,
    this.cardHeight,
    this.onRefreshAfterConflict,
    this.onMissionAccepted,
    this.emptyMessage = 'Aucune mission pour le moment.',
  });

  void _openDetail(BuildContext context, MissionModel mission) {
    context.push(AppRoutes.agentMissionDetail, extra: {'mission': mission},
    );
  }

  @override
  Widget build(BuildContext context) {
    if (missions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ),
      );
    }

    final stripHeight = cardHeight ?? (showAcceptButton ? 210.0 : 168.0);

    return SizedBox(
      height: stripHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < missions.length; i++) ...[
              if (i > 0) const SizedBox(width: 14),
              SizedBox(
                width: 300,
                height: stripHeight,
                child: MissionCard(
                  key: ValueKey('strip-${missions[i].id}'),
                  mission: missions[i],
                  compact: true,
                  fixedHeight: true,
                  showAcceptButton: showAcceptButton,
                  onConflict: onRefreshAfterConflict,
                  onMissionAccepted: onMissionAccepted,
                  onTap: () => _openDetail(context, missions[i]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
