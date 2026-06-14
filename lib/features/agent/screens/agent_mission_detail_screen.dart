import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:fonaco/core/models/mission_model.dart';
import 'package:fonaco/core/providers/auth_provider.dart';
import 'package:fonaco/core/routes/app_routes.dart';
import 'package:fonaco/features/agent/providers/agent_provider.dart';

class AgentMissionDetailScreen extends StatefulWidget {
  final MissionModel? mission;

  const AgentMissionDetailScreen({super.key, this.mission});

  @override
  State<AgentMissionDetailScreen> createState() =>
      _AgentMissionDetailScreenState();
}

class _AgentMissionDetailScreenState extends State<AgentMissionDetailScreen> {
  static const _black = Color(0xFF000000);

  bool _isAccepting = false;
  bool _isDeclining = false;
  Timer? _countdownTimer;

  MissionModel? get _mission => widget.mission;

  String? get _agentUsername =>
      context.read<AuthProvider>().currentUser?.djangoUsername;

  bool get _canAccept =>
      _mission?.canAgentAccept(_agentUsername) ?? false;

  bool get _canDecline =>
      _mission?.canAgentDecline(_agentUsername) ?? false;

  bool get _isActive =>
      _mission != null && MissionModel.isActiveLifecycle(_mission!.status);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startCountdown();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    final mission = _mission;
    if (mission == null) return;
    final hasBoost =
        context.read<AgentProvider>().activeBoost != null;
    if (mission.boostGateRemaining(hasActiveBoost: hasBoost) != null) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  Duration? get _boostRemaining {
    final mission = _mission;
    if (mission == null) return null;
    final hasBoost =
        context.watch<AgentProvider>().activeBoost != null;
    return mission.boostGateRemaining(hasActiveBoost: hasBoost);
  }

  @override
  Widget build(BuildContext context) {
    if (_mission == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: _black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text(
            'Mission introuvable',
            style: TextStyle(color: _black, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    final mission = _mission!;
    final boostRemaining = _boostRemaining;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              mission: mission,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatusBanner(mission: mission),
                    if (boostRemaining != null) ...[
                      const SizedBox(height: 12),
                      _CountdownBanner(
                        remaining: boostRemaining,
                        mission: mission,
                      ),
                    ],
                    const SizedBox(height: 16),
                    _ClientCard(mission: mission),
                    const SizedBox(height: 24),
                    const _SectionTitle('Informations'),
                    const SizedBox(height: 12),
                    _InfoTile(
                      icon: Icons.category_outlined,
                      label: 'Type',
                      value: mission.category ?? 'Livraison',
                    ),
                    const SizedBox(height: 10),
                    _InfoTile(
                      icon: Icons.location_on_outlined,
                      label: 'Adresse',
                      value: mission.address ??
                          mission.pickupAddress ??
                          'Non spécifiée',
                    ),
                    if (mission.destinationAddress != null) ...[
                      const SizedBox(height: 10),
                      _InfoTile(
                        icon: Icons.flag_outlined,
                        label: 'Destination',
                        value: mission.destinationAddress!,
                      ),
                    ],
                    const SizedBox(height: 10),
                    _InfoTile(
                      icon: Icons.schedule_outlined,
                      label: 'Créée',
                      value: mission.createdAt != null
                          ? '${mission.createdAt!.day}/${mission.createdAt!.month}/${mission.createdAt!.year} • ${mission.timeAgo}'
                          : 'Non spécifiée',
                    ),
                    if (mission.etaMinutes != null && _isActive) ...[
                      const SizedBox(height: 10),
                      _InfoTile(
                        icon: Icons.timer_outlined,
                        label: 'Temps estimé',
                        value: '~ ${mission.etaMinutes} min',
                      ),
                    ],
                    const SizedBox(height: 24),
                    const _SectionTitle('Description'),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        mission.description.isNotEmpty
                            ? mission.description
                            : 'Aucune description.',
                        style: const TextStyle(
                          height: 1.55,
                          color: Color(0xFF444444),
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _PriceCard(price: mission.price),
                    const SizedBox(height: 28),
                    _ActionArea(
                      canAccept: _canAccept,
                      canDecline: _canDecline,
                      isActive: _isActive,
                      isAccepting: _isAccepting,
                      isDeclining: _isDeclining,
                      onAccept: _acceptMission,
                      onDecline: _declineMission,
                      onContinue: () => Navigator.pushNamed(
                        context,
                        AppRoutes.agentMissionTracking,
                        arguments: {'mission': mission},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptMission() async {
    if (!_canAccept || _mission == null) return;
    HapticFeedback.lightImpact();
    setState(() => _isAccepting = true);

    try {
      final result = await context
          .read<AgentProvider>()
          .acceptMissionAndUpdateState(_mission!.id);

      if (!mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mission acceptée ! En route.'),
            backgroundColor: Colors.green,
          ),
        );
        final mission = result.mission ?? _mission!;
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.agentMissionTracking,
          arguments: {'mission': mission},
        );
      } else if (result.conflict) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message ??
                  'Cette mission a déjà été acceptée par un autre agent.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Erreur lors de l\'acceptation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAccepting = false);
    }
  }

  Future<void> _declineMission() async {
    if (!_canDecline || _mission == null) return;
    HapticFeedback.lightImpact();
    setState(() => _isDeclining = true);

    try {
      final success = await context
          .read<AgentProvider>()
          .declineAssignedMission(_mission!.id);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mission refusée.'),
            backgroundColor: Colors.black87,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de refuser cette mission.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeclining = false);
    }
  }
}

class _Header extends StatelessWidget {
  final MissionModel mission;
  final VoidCallback onBack;

  const _Header({required this.mission, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _AgentMissionDetailScreenState._black),
          ),
          Expanded(
            child: Text(
              mission.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _AgentMissionDetailScreenState._black,
              ),
            ),
          ),
          if (mission.isUrgent)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Urgent',
                style: TextStyle(
                  color: _AgentMissionDetailScreenState._black,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: _AgentMissionDetailScreenState._black,
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final MissionModel mission;

  const _StatusBanner({required this.mission});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: mission.status.badgeBackgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: mission.status.badgeColor),
          const SizedBox(width: 10),
          Text(
            mission.formattedStatus,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: mission.status.badgeColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownBanner extends StatelessWidget {
  final Duration remaining;
  final MissionModel mission;

  const _CountdownBanner({
    required this.remaining,
    required this.mission,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD400).withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer, color: _AgentMissionDetailScreenState._black),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Priorité boost — visible pour tous dans ${mission.formatCountdown(remaining)}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: _AgentMissionDetailScreenState._black,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  final MissionModel mission;

  const _ClientCard({required this.mission});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFFFD400).withValues(alpha: 0.2),
            backgroundImage: mission.avatarUrl != null
                ? CachedNetworkImageProvider(mission.avatarUrl!)
                : null,
            child: mission.avatarUrl == null
                ? const Icon(Icons.person, color: _AgentMissionDetailScreenState._black)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.clientName ?? 'Client',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: _AgentMissionDetailScreenState._black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mission.isVerified
                      ? 'Client vérifié${mission.clientRating != null ? ' • ${mission.clientRating!.toStringAsFixed(1)} ★' : ''}'
                      : 'Client non vérifié',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD400).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _AgentMissionDetailScreenState._black),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _AgentMissionDetailScreenState._black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final double price;

  const _PriceCard({required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD400),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'Gain estimé',
            style: TextStyle(
              color: _AgentMissionDetailScreenState._black,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${price.toStringAsFixed(0)} FCFA',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: _AgentMissionDetailScreenState._black,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionArea extends StatelessWidget {
  final bool canAccept;
  final bool canDecline;
  final bool isActive;
  final bool isAccepting;
  final bool isDeclining;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onContinue;

  const _ActionArea({
    required this.canAccept,
    required this.canDecline,
    required this.isActive,
    required this.isAccepting,
    required this.isDeclining,
    required this.onAccept,
    required this.onDecline,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    if (isActive) {
      return SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: onContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: _AgentMissionDetailScreenState._black,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Continuer la mission',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ),
      );
    }

    return Column(
      children: [
        if (canAccept)
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: isAccepting ? null : onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: _AgentMissionDetailScreenState._black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isAccepting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Accepter la mission',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
            ),
          ),
        if (canDecline) ...[
          if (canAccept) const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: isDeclining ? null : onDecline,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isDeclining
                  ? SizedBox(
                      width: 20,
                      height: 20,
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
        if (!canAccept && !canDecline && !isActive)
          Text(
            'Aucune action disponible pour cette mission.',
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}
