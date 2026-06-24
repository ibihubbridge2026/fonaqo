import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fonaco/core/models/mission_model.dart';
import 'package:fonaco/core/providers/auth_provider.dart';
import 'package:fonaco/core/routes/app_routes.dart';
import 'package:fonaco/features/agent/providers/agent_provider.dart';
import 'package:go_router/go_router.dart';

/// Carte mission avec action d'acceptation (dashboard agent).
class MissionCard extends StatefulWidget {
  final MissionModel mission;
  final VoidCallback? onMissionAccepted;
  final VoidCallback? onConflict;
  final VoidCallback? onDeclined;
  final bool compact;
  final bool fixedHeight;
  final bool showAcceptButton;
  final bool showDeclineButton;
  final VoidCallback? onTap;

  const MissionCard({
    super.key,
    required this.mission,
    this.onMissionAccepted,
    this.onConflict,
    this.onDeclined,
    this.compact = false,
    this.fixedHeight = false,
    this.showAcceptButton = true,
    this.showDeclineButton = false,
    this.onTap,
  });

  @override
  State<MissionCard> createState() => _MissionCardState();
}

class _MissionCardState extends State<MissionCard> {
  bool _isAccepting = false;
  bool _isDeclining = false;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startCountdownIfNeeded();
    });
  }

  @override
  void didUpdateWidget(covariant MissionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mission.id != widget.mission.id ||
        oldWidget.mission.createdAt != widget.mission.createdAt) {
      _startCountdownIfNeeded();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdownIfNeeded() {
    _countdownTimer?.cancel();
    final hasBoost =
        context.read<AgentProvider>().activeBoost != null;
    final remaining =
        widget.mission.boostGateRemaining(hasActiveBoost: hasBoost);
    if (remaining != null) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  String get _locationLabel {
    return widget.mission.address ??
        widget.mission.pickupAddress ??
        'Cotonou';
  }

  String? get _agentUsername =>
      context.read<AuthProvider>().currentUser?.djangoUsername;

  bool get _canAccept =>
      widget.showAcceptButton &&
      widget.mission.canAgentAccept(_agentUsername);

  bool get _canDecline =>
      widget.showDeclineButton &&
      widget.mission.canAgentDecline(_agentUsername);

  Duration? get _boostRemaining {
    final hasBoost =
        context.read<AgentProvider>().activeBoost != null;
    return widget.mission.boostGateRemaining(hasActiveBoost: hasBoost);
  }

  Future<void> _acceptMission() async {
    if (_isAccepting || !_canAccept) return;

    setState(() => _isAccepting = true);

    final agentProvider = context.read<AgentProvider>();
    final result =
        await agentProvider.acceptMissionAndUpdateState(widget.mission.id);

    if (!mounted) return;

    setState(() => _isAccepting = false);

    if (result.success) {
      widget.onMissionAccepted?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mission acceptée ! En route.'),
          backgroundColor: Colors.green,
        ),
      );
      final mission = result.mission ?? widget.mission;
      context.push(AppRoutes.agentMissionTracking, extra: {'mission': mission},
      );
      return;
    }

    if (result.conflict) {
      widget.onConflict?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message ??
                'Cette mission a déjà été acceptée par un autre agent.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message ?? 'Impossible d\'accepter la mission'),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _declineMission() async {
    if (_isDeclining || !_canDecline) return;

    setState(() => _isDeclining = true);
    final success = await context
        .read<AgentProvider>()
        .declineAssignedMission(widget.mission.id);

    if (!mounted) return;
    setState(() => _isDeclining = false);

    if (success) {
      widget.onDeclined?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mission refusée.'),
          backgroundColor: Colors.black87,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Impossible de refuser cette mission.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;
    const blackTitle = Color(0xFF000000);
    final titleStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: compact ? 14 : 16,
      color: blackTitle,
    );
    final boostRemaining = _boostRemaining;

    final mainRow = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: compact ? 20 : 24,
          backgroundColor: const Color(0xFFFFD400).withValues(alpha: 0.15),
          child: Icon(
            Icons.work_outline,
            color: blackTitle,
            size: compact ? 18 : 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.mission.title,
                style: titleStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: compact ? 14 : 16,
                    color: const Color(0xFF777777),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _locationLabel,
                      style: TextStyle(
                        color: const Color(0xFF777777),
                        fontSize: compact ? 12 : 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (widget.mission.clientName != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: compact ? 14 : 16,
                      color: const Color(0xFF777777),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.mission.clientName!,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: compact ? 11 : 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${widget.mission.price.toStringAsFixed(0)} F',
                style: TextStyle(
                  color: const Color(0xFFE0B800),
                  fontWeight: FontWeight.w900,
                  fontSize: compact ? 14 : 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (!widget.showAcceptButton) ...[
                const SizedBox(height: 4),
                Text(
                  widget.mission.formattedStatus,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: widget.mission.status.badgeColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    final card = Container(
      margin: EdgeInsets.only(bottom: compact ? 0 : 14),
      padding: EdgeInsets.all(compact ? 14 : 18),
      height: widget.fixedHeight ? double.infinity : null,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 18 : 22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize:
            widget.fixedHeight ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (widget.fixedHeight) Expanded(child: mainRow) else mainRow,
          if (boostRemaining != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: Color(0xFF000000),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Priorité boost — dispo dans ${widget.mission.formatCountdown(boostRemaining)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF000000),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (widget.mission.etaMinutes != null &&
              MissionModel.isActiveLifecycle(widget.mission.status)) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Color(0xFF555555)),
                const SizedBox(width: 6),
                Text(
                  'ETA ~ ${widget.mission.etaMinutes} min',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF555555),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          if (_canAccept) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isAccepting ? null : _acceptMission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD400),
                  foregroundColor: blackTitle,
                  elevation: 0,
                  minimumSize: Size(double.infinity, widget.compact ? 44 : 48),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isAccepting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: blackTitle,
                        ),
                      )
                    : Text(
                        compact ? 'Accepter' : 'Accepter la mission',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ],
          if (_canDecline) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isDeclining ? null : _declineMission,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade300),
                  minimumSize: Size(double.infinity, widget.compact ? 40 : 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isDeclining
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.red.shade700,
                        ),
                      )
                    : const Text(
                        'Refuser la mission',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ],
      ),
    );

    if (widget.onTap != null) {
      return InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(compact ? 18 : 22),
        child: card,
      );
    }
    return card;
  }
}
